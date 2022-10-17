pipeline 
{
	agent any
    
	environment {
		// coorindate for check runs
		checkrun_repo_commit = "${ghprbGhRepository}/${ghprbActualCommit}"
	}
       
	stages { 
	
		stage('Checkrun update') 
		{
		
			steps {
				
				echo("Building check run coordinate: ")
				echo("ghprbGhRepository = ${ghprbGhRepository}")
				echo("ghprbActualCommit = ${ghprbActualCommit}")
				echo("checkrun_repo_commit = ${checkrun_repo_commit}")
			
				build(job: 'github-commit-checkrun',
					parameters:
					[
						string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
						string(name: 'src_Job_id', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
						string(name: 'src_details_url', value: "${env.BUILD_URL}"),
						string(name: 'checkrun_status', value: "in_progress")
					],
					wait: false, propagate: false)
			} // steps
		} // stage('Checkrun update') 
		
		stage('Initialize') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
						
						slackSend (color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
						mattermostSend color: "#FFFF00", message: "Build Started - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
								
						dir('macros') {
							deleteDir()
						}			
						dir('qa_html') {
							deleteDir()
						}			
						dir('report') {
						 	deleteDir()
						}		
						dir('install') {
						 	deleteDir()
						}		
						dir('build') {
						 	deleteDir()
						}
					
						sh('hostname')
						sh('pwd')
						sh('env')
						sh('ls -lvhc')

												
						script
						{
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${sha1}"
							
							if (params.upstream_build_description)
							{
								echo ("Override build descriiption with ${upstream_build_description}");
    						currentBuild.description = "${upstream_build_description}"
							}
						}
					}
				}
			}
		}
		
		stage('ContainerCheck') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
						
						dir('utilities/jenkins/built-test/') {
							
							sh('$singularity_exec_sphenix tcsh -f singularity-check.sh')
						
						}
					}
				}
			}
		}

		stage('Git Checkout')
		{
			
			steps 
			{
				timestamps { 
					ansiColor('xterm') {
						
						dir('macros') {
							
							checkout(
							   [
				            $class: 'GitSCM',
				            extensions: [               
				                [$class: 'CleanCheckout'],     
				                
				                [
				                $class: 'PreBuildMerge',
				                options: [
				                    mergeRemote: 'origin',
				                    mergeTarget: 'master'
				                    ]
				                ],
				            ],
				            branches: [
				                [name: "${sha1}"]
				            ], 
				            userRemoteConfigs: 
				            [[
				                credentialsId: 'sPHENIX-bot', 
				                url: 'https://github.com/${ghprbGhRepository}.git',
				                refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
				                branch: ('*')
				            ]]
				        ] //checkout
					    )// checkout
	    
	
						}//						dir('macros') {
						

					}//					ansiColor('xterm') {
					
				}//				timestamps { 
				
			}//			steps 
			
		}//stage('SCM Checkout')

		stage('Report')
		{
			
			steps 
			{
				timestamps { 
					ansiColor('xterm') {
						
                        
                        dir('report')
                        {
                            sh('ls -lvhc')
                                    
                            script
                            {
                                
                                echo("start report building ...");
                                sh ('pwd');
                                
                                def report_content = """
## Please start the CI check manually (Beta test, [feedback](mailto:jhuang@bnl.gov))

This is an automatic message to assist manually starting CI check for this pull request, [commit ${ghprbActualCommit}](${ghprbPullLink}/commits/${ghprbActualCommit}). [`macros`](https://github.com/sPHENIX-Collaboration/macros) pull request require a manual start for CI checks, in particular selecting which [`coresoftware`](https://github.com/sPHENIX-Collaboration/coresoftware) and [`calibrations`](https://github.com/sPHENIX-Collaboration/calibrations) versions to check against this `macros` pull request. 

Please make your input here and start the Build: 

[![build](https://img.shields.io/badge/click%20to%20start-build-green.svg)](https://web.sdcc.bnl.gov/jenkins-sphenix/job/sPHENIX/job/Build-Master-gcc8/parambuild/?sha_macros=origin/pr/${ghprbPullId}/merge&upstream_build_description=Check%20%3Ca%20href%3D%22https%3A%2F%2Fgithub.com%2FsPHENIX-Collaboration%2Fmacros%2Fpull%2F${ghprbPullId}%22%3Emacros%20Pull%20request%20${ghprbPullId}%3C%2Fa%3E&ghprbPullLink=https://github.com/sPHENIX-Collaboration/macros/pull/${ghprbPullId}&checkrun_repo_commit=sPHENIX-Collaboration%2Fmacros%2F${ghprbActualCommit})

Note: 
1. if needed, fill in the pull request ID for the [`coresoftware` pull request](https://github.com/sPHENIX-Collaboration/coresoftware/pull/), e.g. `origin/pr/1697/merge` for PR#1697 in `sha_coresoftware`. Default is to check with the `master` branch.
2. click `Build` button at the end of the long web page to start the test

--------------------
_Automatically generated by [sPHENIX Jenkins continuous integration](https://web.sdcc.bnl.gov/jenkins-sphenix/job/sPHENIX/job/sPHENIX_macros_PullRequest/display/redirect)_
[![sPHENIX](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/sphenix-logo-white-bg-72p.png)](https://www.sphenix.bnl.gov/web/) &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; [![jenkins.io](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_title-72p.png)](https://jenkins.io/)
"""
                            
                                currentBuild.description = "${currentBuild.description}\n${report_content}"	
                                
                                build(job: 'github-comment-label',
                                    parameters:
                                    [
                                        string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
                                        string(name: 'LabelCategory', value: ""),
                                        string(name: 'githubComment', value: "${report_content}")
                                    ],
                                    wait: false, propagate: false)
                                
                                build(job: 'github-commit-checkrun',
                                    parameters:
                                    [
                                        string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
                                        string(name: 'src_Job_id', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
                                        string(name: 'src_details_url', value: "${env.BUILD_URL}"),
                                        string(name: 'checkrun_status', value: "completed"),
                                        string(name: 'checkrun_conclusion', value: "${currentBuild.currentResult}"),
                                        string(name: 'output_title', value: "sPHENIX Jenkins Report for ${env.JOB_NAME}"),
                                        string(name: 'output_summary', value: "[![Build Status](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) [builds and tests overall are ${currentBuild.currentResult}](${env.BUILD_URL})."),
                                        string(name: 'output_text', value: "${currentBuild.displayName}\n\n${currentBuild.description}")
                                    ],
                                    wait: false, propagate: false
                                ) // build(job: 'github-commit-checkrun',
                        
                            }// script
                            
                        }
						

					}//					ansiColor('xterm') {
					
				}//				timestamps { 
				
			}//			steps 
			
		}//stage('SCM Checkout')
		
		
		



		
	}//stages
		
	post {	
		success {
			slackSend (color: '#00FF00', message: "Pull request ${ghprbGhRepository}.${ghprbPullId} check SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})  for ${ghprbPullLink}")
			mattermostSend color: "#00FF00", message: "Pull request ${ghprbGhRepository}.${ghprbPullId} check SUCCESSFUL: Job ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
						
		}
		failure {
			slackSend (color: '#FF0000', message: "Pull request ${ghprbGhRepository}.${ghprbPullId} check FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})  for ${ghprbPullLink}")
			mattermostSend color: "#FF0000", message: "Pull request ${ghprbGhRepository}.${ghprbPullId} check FAILED: Job ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
						
		}
		unstable {
			slackSend (color: '#FFF000', message: "Pull request ${ghprbGhRepository}.${ghprbPullId} check UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})  for ${ghprbPullLink}")
			mattermostSend color: "#FFF000", message: "Pull request ${ghprbGhRepository}.${ghprbPullId} check UNSTABLE: Job ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
						
		}
	}
	
}//pipeline 
