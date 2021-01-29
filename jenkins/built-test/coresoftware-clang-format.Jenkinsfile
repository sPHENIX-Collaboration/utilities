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
						 
						dir('coresoftware') {
							deleteDir()
						}			 
					
						sh('hostname')
						sh('pwd')
						sh('env')
						sh('ls -lvhc')

												
						script
						{
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${sha1}"
							
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
						
						dir('coresoftware') {
							// git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
							
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
				                url: 'https://github.com/${ghprbGhRepository}.git', // https://github.com/sPHENIX-Collaboration/coresoftware.git
				                refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
				                branch: ('*')
				            ]]
				        ] //checkout
					    )// checkout
	    
	
						}//						dir('coresoftware') {
						

					}//					ansiColor('xterm') {
					
				}//				timestamps { 
				
			}//			steps 
			
		}//stage('SCM Checkout')
		
	}//stages
		
	post {
		always{
    
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
			
		}
	
	}
	
}//pipeline 
