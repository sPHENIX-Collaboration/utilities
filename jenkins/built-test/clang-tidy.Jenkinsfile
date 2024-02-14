pipeline 
{
	agent any
           
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
		
		stage('Initialize') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
																
						script {
						
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${sha_coresoftware}"
							currentBuild.description = "${upstream_build_description} / <a href=\"${git_url_coresoftware}\">coresoftware</a> # ${sha_coresoftware}" 
							
						}
										
						dir('coresoftware') {
							deleteDir()
						}
						dir('report') {
							deleteDir()
						}
						sh('rm -fv cppcheck-result.xml')
					
						sh('hostname')
						sh('pwd')
						sh('env')
						sh('ls -lvhc')

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
							  			mergeTarget: "$mergeTarget_coresoftware"
							  			]
							    	],
						   		],
							  	branches: [
							    	[name: "${sha_coresoftware}"]
							    ], 
							  	userRemoteConfigs: 
							  	[[
							    	//credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
							     	credentialsId: 'sPHENIX-bot', 
							     	url: '${git_url_coresoftware}',
							     	refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
							    	branch: ('*')
							  	]]
								] //checkout
							)//checkout
						}//						dir('coresoftware') {


						dir('online_distribution') {
							git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/online_distribution.git'
						}


						dir('acts') {

							checkout(
								[
						 			$class: 'GitSCM',
									extensions: [               
										[$class: 'SubmoduleOption',
										    disableSubmodules: false,
										    parentCredentials: true,
										    recursiveSubmodules: true,
										    reference: '',
										    trackingSubmodules: false],
										[$class: 'CleanBeforeCheckout'], 
										[$class: 'CleanCheckout'] 
									],
									branches: [
									[name: "sPHENIX"]
							        	], 
									userRemoteConfigs: 
									[[
									credentialsId: 'sPHENIX-bot', 
									url: 'https://github.com/sPHENIX-Collaboration/acts.git',
									refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master')
									]]
								] //checkout
							)//checkout						
						}//	dir('acts') 


					}
				}
			}
		}//stage('SCM Checkout')
		
			
    stage('clang-tidy')
    {
      steps 
      {
        
        sh ('$singularity_exec_sphenix /bin/bash -v utilities/jenkins/built-test/clang-tidy.sh')

      }
    }// Stage - cpp check

    stage('clang-tidy-analysis')
    {
      
      steps 
      {
        archiveArtifacts artifacts: 'clang-tidy-result.txt'
        recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 100, tool: clangTidy(pattern: 'clang-tidy-result.txt')
      }										
    } // 				stage('sPHENIX-Build')

	}//stages
		
	post {
		always{
		  
			dir('report')
			{
				sh('ls -lvhc')
			  writeFile file: "clang-tidy.md", text: "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) `clang-tidy` [is ${currentBuild.currentResult}](${env.BUILD_URL}), [:bar_chart:`cppcheck` report (full)](${env.BUILD_URL}/cppcheck/)/[(new)](${env.BUILD_URL}/cppcheck/new/)"				
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
					string(name: 'output_summary', value: "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) `clang-tidy` [is ${currentBuild.currentResult}](${env.BUILD_URL}), [:bar_chart:`cppcheck` report (full)](${env.BUILD_URL}/cppcheck/)/[(new)](${env.BUILD_URL}/cppcheck/new/)"),
					string(name: 'output_text', value: "${currentBuild.displayName}\n\n${currentBuild.description}")
				],
				wait: false, propagate: false
			) // build(job: 'github-commit-checkrun',
		
		}
	
	}
	
}//pipeline 
