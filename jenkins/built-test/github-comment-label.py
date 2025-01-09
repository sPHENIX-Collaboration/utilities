import sys
import os
import pprint

import json
from datetime import datetime, timedelta
import time

from github import Github, GithubIntegration

# print('Disable GitHub tagging!')
# exit(0)

#########################
# Input and checks
#########################

# Parse pull requests e.g. https://github.com/sPHENIX-Test/coresoftware/pull/86
if os.getenv("ghprbPullLink") is None:
    print('Ignore this build as ghprbPullLink is emtpy')
    exit(0)

ghprbPullLink = os.environ['ghprbPullLink']

ghprbPullLinkItems = ghprbPullLink.split('/')

pullRequestID = int(ghprbPullLinkItems[-1]);
assert pullRequestID >0, 'Invalid pull request ID : {} from {}'.format( pullRequestID, ghprbPullLink);
assert ghprbPullLinkItems[-2] == "pull"
repoName = ghprbPullLinkItems[-3];
organizationName = ghprbPullLinkItems[-4];

print("Processing pull request {} -> {}.{} #{} " . format(ghprbPullLinkItems, organizationName, repoName, pullRequestID) );



#########################
# Authentification
#########################


with open (os.environ['HOME'] + "/.ssh/github.app.sphenix-jenkins-ci.appid", "r") as myfile:
    APPID=myfile.read().strip()
with open (os.environ['HOME'] + "/.ssh/github.app.sphenix-jenkins-ci.installationid", "r") as myfile:
    INSTALLATIONID=myfile.read().strip()
with open(os.environ['HOME'] + "/.ssh/github.app.sphenix-jenkins-ci.private-key.pem", 'rb') as fh:
    signing_key = fh.read().decode()

print(f"Authentication with private key for app {APPID} installation {INSTALLATIONID} ...")

integration = GithubIntegration(APPID, signing_key)
jwt_token = integration.create_jwt()
access_obj = integration.get_access_token(INSTALLATIONID)

pprint.pprint(access_obj.__dict__);

token = access_obj.token

#########################
# Label definitions
# https://pygithub.readthedocs.io/en/latest/github_objects/Label.html
#########################

labelStatusOperations = ['PASS', 'FAIL', 'PENDING', 'AVAILABLE']
labelStatusColors = {
"PASS": "70f4ac",
"FAIL": "cc0407",
"PENDING": "2b659b",
"AVAILABLE": "edc825",
}
labelStatusDesciptions = {
"PASS": "passed. ",
"FAIL": "failed!",
"PENDING": "is still running. ",
"AVAILABLE": "result is available.",
}

LabelStatus = os.environ['LabelStatus']

LabelURL = os.getenv("BUILD_URL")
if os.getenv("githubComment") is not None:
    LabelURL = os.getenv("LabelURL")

#########################
# Talk to GitHub
#########################

gh = Github(token)

org = gh.get_organization(organizationName)
repo = org.get_repo(repoName)
pr = repo.get_pull(pullRequestID)

# githubComment
if os.getenv("githubComment") is not None:
    print ("Create comment -", os.getenv("githubComment"));
    ############## COMMENT OUT TO TMP DISABLE ##############
    pr.create_issue_comment(os.getenv("githubComment"))

# LabelStatus
if LabelStatus in labelStatusOperations:
    assert os.getenv("LabelCategory") is not None, 'LabelCategory is empty'
    LabelCategory = os.getenv("LabelCategory")
    
    repo_labels = [label.name for label in repo.get_labels()];
    print('Repository labels - ', repo_labels)
    
    labelList = pr.get_labels();
    
    labels = [label.name for label in labelList];
    print('Current PR labels - ', labels)
    
    for status in labelStatusOperations:
        labelName = "CI-{}-{}".format(LabelCategory, status)
        
        if not (labelName in repo_labels):
            # create_label(name, color, description=NotSet)
            print ('create label ', labelName, labelStatusColors[status], "{} {}".format(LabelCategory, labelStatusDesciptions[status]))
            repo.create_label(labelName, labelStatusColors[status], "{} {}".format(LabelCategory, labelStatusDesciptions[status]));
            
        if LabelStatus == status:
            if not (labelName in labels):
                print ("add label ", labelName);
                ############## COMMENT OUT TO TMP DISABLE ##############
                pr.add_to_labels(labelName);
        else:
            if labelName in labels:
                print ("remove label ", labelName);
                ############## COMMENT OUT TO TMP DISABLE ##############
                pr.remove_from_labels(labelName);
