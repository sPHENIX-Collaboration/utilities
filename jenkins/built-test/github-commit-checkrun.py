
import sys
import os
import pprint

import json
from datetime import datetime, timedelta
import time

from github import Auth, GithubIntegration, Github

#########################
# Input and checks
#########################

if os.getenv("checkrun_repo_commit") is None:
    print('Ignore this build as checkrun_repo_commit is emtpy')
    exit(0)

if os.getenv("src_Job_id") is None:
    print('Ignore this build as src_Job_id is emtpy')
    exit(0)

if os.getenv("checkrun_status") is None:
    print('Ignore this build as checkrun_status is emtpy')
    exit(0)

checkrun_repo_commit = os.environ['checkrun_repo_commit']

src_Job_id = os.environ['src_Job_id']

checkrun_status = os.environ['checkrun_status']

src_details_url = os.getenv('src_details_url')
checkrun_conclusion = os.getenv('checkrun_conclusion')
output_title = os.getenv('output_title')
output_summary = os.getenv('output_summary')
output_text = os.getenv('output_text')

checkrun_conclusion_translation = {
    # Jenkins to GitHub CheckRun translation
    "SUCCESS": "success", 
    "UNSTABLE": "action_required", 
    "FAILURE": "failure", 
    "ABORTED": "cancelled", 
    "NOT_BUILT": "skipped", 
    
    # GitHub CheckRun list
    "success": "success", 
    "failure": "failure", 
    "neutral": "neutral", 
    "cancelled": "cancelled", 
    "skipped": "skipped", 
    "timed_out": "timed_out", 
    "action_required": "action_required", 
}
if checkrun_conclusion is not None:
    checkrun_conclusion_orig = checkrun_conclusion
    if checkrun_conclusion_orig in checkrun_conclusion_translation.keys(): 
        checkrun_conclusion = checkrun_conclusion_translation[checkrun_conclusion_orig]
        print(f"Translate checkrun_conclusion from {checkrun_conclusion_orig} to {checkrun_conclusion}")
    else:
        print(f"Invalid conclusion of {checkrun_conclusion}. Available conclusions are:")
        pprint.pprint(checkrun_conclusion_translation)
        assert checkrun_conclusion_orig in checkrun_conclusion_translation.keys()
        
checkrun_repo_commit_items = checkrun_repo_commit.split('/')
assert len(checkrun_repo_commit_items) == 3, f"invalid checkrun_repo_commit={checkrun_repo_commit}"


checkrun_organziation = checkrun_repo_commit_items[0];
checkrun_repo = checkrun_repo_commit_items[1];
checkrun_commit = checkrun_repo_commit_items[2];

print(f"Processing commit {checkrun_organziation} / {checkrun_repo} / {checkrun_commit} ");


#########################
# Authentification
#########################



with open(os.path.expanduser("~/.ssh/github.app.sphenix-jenkins-ci.appid")) as f:
    APPID = int(f.read().strip())
with open(os.path.expanduser("~/.ssh/github.app.sphenix-jenkins-ci.installationid")) as f:
    INSTALLATIONID = int(f.read().strip())
with open(os.path.expanduser("~/.ssh/github.app.sphenix-jenkins-ci.private-key.pem"), "r") as f:
    signing_key = f.read()

print(f"Authentication with private key for app {APPID} installation {INSTALLATIONID} ...")

# Create App auth, then get a Github client bound to the installation.
app_auth = Auth.AppAuth(APPID, signing_key)
gi = GithubIntegration(auth=app_auth)
gh = gi.get_github_for_installation(INSTALLATIONID)  # Access token handled & refreshed for you

#########################
# Talk to GitHub
#########################

gh = Github(login_or_token=access_obj.token)

# pprint.pprint(gh.__dict__);

org = gh.get_organization(checkrun_organziation)
repo = org.get_repo(checkrun_repo)
commitObj = repo.get_commit(checkrun_commit)

print(f"Processing commit {checkrun_commit} with {commitObj.get_check_runs().totalCount} check runs", );
#pprint.pprint(commitObj.__dict__);

this_check_run_obj = None
check_runs = commitObj.get_check_runs()
for check_run in  commitObj.get_check_runs():
    print(f"Processing check_run: {check_run} ID={check_run.external_id}")
    
    if check_run.external_id == src_Job_id:
        this_check_run_obj = check_run
        print(f"Found existing check_run: {check_run} ID={check_run.external_id}")
        # pprint.pprint(check_run.__dict__)
        break

if this_check_run_obj is None:
    this_check_run_obj = repo.create_check_run(src_Job_id, checkrun_commit, details_url=src_details_url, external_id=src_Job_id, status="queued")
    print(f"No existing check_run. Making a new one: {this_check_run_obj} ID={this_check_run_obj.external_id}")

# Final updates

if (checkrun_conclusion is not None) : 
    print(f"Update checkrun_conclusion: {checkrun_conclusion}")
    this_check_run_obj.edit(details_url = src_details_url, conclusion=checkrun_conclusion)
else:
    print(f"Update checkrun_status: {checkrun_status}")
    this_check_run_obj.edit(details_url = src_details_url, status=checkrun_status)

if (output_title is not None) and (output_summary is not None):    
    dict_output = {"title" : output_title, "summary": output_summary}
    if output_text is not None:
    	dict_output['text'] = output_text
    print(f"Update output:")
    pprint.pprint(dict_output)
    this_check_run_obj.edit(output=dict_output)
    
