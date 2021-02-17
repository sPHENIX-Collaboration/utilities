pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
    options {
        timeout(time: 1, unit: 'HOURS') 
    }
       
	stages { 
	
		stage('Checkrun update') 
		{
		
			steps {
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
		
		stage('Prebuild-Cleanup') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
					
					
						build(job: 'github-comment-label',
		    			parameters:
		    			[
		    				string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
			    			string(name: 'LabelCategory', value: "DST-readback"),
			    			string(name: 'LabelStatus', value: "PENDING")
			    		],
		    			wait: false, propagate: false)
					
						script {
						
							currentBuild.description = "${upstream_build_description}" 
			
							if (fileExists('./install'))
							{
								sh "rm -fv ./install"
							}
							if (fileExists('./calibrations'))
							{
								sh "rm -fv ./calibrations"
							}						
							if (fileExists('./build'))
							{
								sh "rm -fv ./build"
							}						
						}						
    				
						echo("link builds to ${build_src}")
						sh('ln -svfb ${build_src}/install ./install')
						sh('ln -svfb ${build_src}/calibrations ./calibrations')

						dir('macros')
						{
							deleteDir()
						}	

						dir('coresoftware') {
							deleteDir()
						}

						dir('report')
						{
							deleteDir()
    				}
    				
						sh('ls -lvhc')
						
						slackSend (color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
						
					}
				}
			}
		}
	
		stage('Initialize') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
					
						sh('hostname')
						sh('pwd')
						sh('env')
						
						sh('ls -lvhc')
    				
						dir('utilities/jenkins/built-test/') {
							
							sh('$singularity_exec_sphenix  tcsh -f singularity-check.sh ${build_type}')
						
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
						
						dir('macros')
						{			
							
							checkout(
								[
						 			$class: 'GitSCM',
						   		extensions: [               
							   		[$class: 'CleanCheckout'],       
							     	[
							   			$class: 'PreBuildMerge',
							    		options: [
											mergeRemote: 'origin',
							  			mergeTarget: 'readback_check'
							  			]
							    	],   
							     	[
							   			$class: 'PreBuildMerge',
							    		options: [
											mergeRemote: 'origin',
							  			mergeTarget: 'master'
							  			]
							    	],
						   		],
							  	branches: [
							    	[name: "${sha_macros}"]
							    ], 
							  	userRemoteConfigs: 
							  	[[
							     	credentialsId: 'sPHENIX-bot', 
							     	url: '${git_url_macros}',
							     	refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
							    	branch: ('*')
							  	]]
								] //checkout
							)//checkout
							
    				}	
    				
    				// for QA macros, just use the default repository then...
						dir('coresoftware') {
							git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
						}
						
					}
				}
			}
		}//stage('SCM Checkout')
		
		
		stage('Test-Generation')
		{
			
			
			steps 
			{
					
				sh("$singularity_exec_sphenix sh utilities/jenkins/built-test/test-DST-readback-detector.sh sPHENIX 2 0")
														
			}				
					
		}
		
	}//stages

	
	post {
	
		always{
		  
			dir('report')
			{
			  writeFile file: "DST-readback.md", text: "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) Generating DST and readback: [build is ${currentBuild.currentResult}](${env.BUILD_URL}) "				
			}
		  		  
			archiveArtifacts artifacts: 'report/*.md'
			
			build(job: 'github-commit-checkrun',
				parameters:
				[
					string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
					string(name: 'src_Job_id', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
					string(name: 'src_details_url', value: "${env.BUILD_URL}"),
					string(name: 'checkrun_status', value: "completed"),
					string(name: 'checkrun_conclusion', value: "${currentBuild.currentResult}"),
					string(name: 'output_title', value: "sPHENIX Jenkins Report for ${env.JOB_NAME}"),
					string(name: 'output_summary', value: "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) Generating DST and readback: [build is ${currentBuild.currentResult}](${env.BUILD_URL}) "),
					string(name: 'output_text', value: "${currentBuild.displayName}\n\n${currentBuild.description}")
				],
				wait: false, propagate: false
			) // build(job: 'github-commit-checkrun',
			
			archiveArtifacts artifacts: 'macros/**/*.log'
		}

		success {
		
			build(job: 'github-comment-label',
			  parameters:
			  [
					string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
					string(name: 'LabelCategory', value: "DST-readback"),
					string(name: 'LabelStatus', value: "PASS")
				],
				wait: false, propagate: false)
				
			slackSend (color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
		failure {
			build(job: 'github-comment-label',
			  parameters:
			  [
					string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
					string(name: 'LabelCategory', value: "DST-readback"),
					string(name: 'LabelStatus', value: "FAIL")
				],
				wait: false, propagate: false)
			slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
		unstable {
			build(job: 'github-comment-label',
			  parameters:
			  [
					string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
					string(name: 'LabelCategory', value: "DST-readback"),
					string(name: 'LabelStatus', value: "FAIL")
				],
				wait: false, propagate: false)
			slackSend (color: '#FFF000', message: "UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
	}
}//pipeline 

