pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
       
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
																
						// build(job: 'github-comment-label',
		    			// parameters:
		    			// [
		    			// 	string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
			    		// 	string(name: 'LabelCategory', value: "cpp-check"),
			    		// 	string(name: 'LabelStatus', value: "PENDING")
			    		// ],
		    			// wait: false, propagate: false)
						
						script {
						
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${sha_online_distribution}"
							currentBuild.description = "${upstream_build_description} / <a href=\"${git_url_online_distribution}\">online_distribution</a> # ${sha_online_distribution}" 
							
						}
										
						dir('online_distribution') {
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
						
						dir('online_distribution') {
							// git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/online_distribution.git'
							
							checkout(
								[
						 			$class: 'GitSCM',
						   		extensions: [               
							   		[$class: 'CleanCheckout'],     
							     	[
							   			$class: 'PreBuildMerge',
							    		options: [
											mergeRemote: 'origin',
							  			mergeTarget: "$mergeTarget_online_distribution"
							  			]
							    	],
						   		],
							  	branches: [
							    	[name: "${sha_online_distribution}"]
							    ], 
							  	userRemoteConfigs: 
							  	[[
							    	//credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/online_distribution.git'
							     	credentialsId: 'sPHENIX-bot', 
							     	url: '${git_url_online_distribution}',
							     	refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
							    	branch: ('*')
							  	]]
								] //checkout
							)//checkout
						}//						dir('online_distribution') {
						
					}
				}
			}
		}//stage('SCM Checkout')
		
	    stage ('Git mining') {
            steps {
                discoverGitReferenceBuild (requiredResult: hudson.model.Result.SUCCESS)
                mineRepository()
                gitDiffStat()
                }
	    }
		// hold this until jenkins supports nested parallel
		//stage('Build')
		//{
		//	parallel {
			
				stage('cpp-check')
				{
					steps 
					{
                        writeFile file: "build.sh", text:'''#!/usr/bin/env tcsh
                        
                            source /opt/sphenix/core/bin/sphenix_setup.csh -n new; 

                            which cppcheck; 

                            if (-e  cppcheck-result.xml) then
                                rsync -avl --remove-source-files cppcheck-result.xml cppcheck-result.xml.backup
                            endif

                            cppcheck -q --inline-suppr  --enable=warning --enable=performance --platform=unix64 --inconclusive --xml --xml-version=2 -j 10 --std=c++20 ./online_distribution > & cppcheck-result.xml

                            ls -hvl $PWD/cppcheck-result.xml
                            wc -l cppcheck-result.xml

                            head -n 10 cppcheck-result.xml
                            ''';//  writeFile file: "build.sh", text:'''#!/usr/bin/env tcsh

                        sh('chmod +x build.sh');
                        sh('$singularity_exec_sphenix tcsh build.sh')
		   		    }
				}// Stage - cpp check
				 
				
					    
								stage('cpp-check-analysis')
								{
									
									steps 
									{
										archiveArtifacts artifacts: 'cppcheck-result.xml'
						        			recordIssues qualityGates: [[threshold: 0.5, type: 'NEW', unstable: false], [threshold: 0.5, type: 'NEW_HIGH', unstable: false]], tools: [cppCheck(pattern: 'cppcheck-result.xml')]
									}										
								} // 				stage('sPHENIX-Build')
	}//stages
		
	post {
		always{
		  
			dir('report')
			{
				sh('ls -lvhc')
			  writeFile file: "cpp-check.md", text: "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) `cpp-check` [is ${currentBuild.currentResult}](${env.BUILD_URL}), [:bar_chart:`cppcheck` report (full)](${env.BUILD_URL}/cppcheck/)/[(new)](${env.BUILD_URL}/cppcheck/new/)"				
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
					string(name: 'output_summary', value: "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) `cpp-check` [is ${currentBuild.currentResult}](${env.BUILD_URL}), [:bar_chart:`cppcheck` report (full)](${env.BUILD_URL}/cppcheck/)/[(new)](${env.BUILD_URL}/cppcheck/new/)"),
					string(name: 'output_text', value: "${currentBuild.displayName}\n\n${currentBuild.description}")
				],
				wait: false, propagate: false
			) // build(job: 'github-commit-checkrun',
		
		}
	
		// success {
		
		// 	build(job: 'github-comment-label',
		// 	  parameters:
		// 	  [
		// 			string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
		// 			string(name: 'LabelCategory', value: "cpp-check"),
		// 			string(name: 'LabelStatus', value: "AVAILABLE")
		// 		],
		// 		wait: false, propagate: false)		
		// }
		// failure {
		
		// 	build(job: 'github-comment-label',
		// 	  parameters:
		// 	  [
		// 			string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
		// 			string(name: 'LabelCategory', value: "cpp-check"),
		// 			string(name: 'LabelStatus', value: "FAIL")
		// 		],
		// 		wait: false, propagate: false)
		
		// }
		// unstable {
		
		// 	build(job: 'github-comment-label',
		// 	  parameters:
		// 	  [
		// 			string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
		// 			string(name: 'LabelCategory', value: "cpp-check"),
		// 			string(name: 'LabelStatus', value: "AVAILABLE")
		// 		],
		// 		wait: false, propagate: false)
				
		// }
	}
	
}//pipeline 

