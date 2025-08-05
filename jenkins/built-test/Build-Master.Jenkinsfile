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
			    		// 	string(name: 'LabelCategory', value: "build-${system_config}-${build_type}"),
			    		// 	string(name: 'LabelStatus', value: "PENDING")
			    		// ],
		    			// wait: false, propagate: false)
						
						script {
						
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${system_config} - ${build_type} - ${sha_coresoftware}"
							currentBuild.description = "${upstream_build_description} / <a href=\"${git_url_coresoftware}\">coresoftware</a> # ${sha_coresoftware} - ${system_config} - ${build_type}" 
							
						}
										
						dir('build')
						{
							sh('chmod -R 755 .')
							deleteDir()
						}	

						dir('coresoftware') {
							deleteDir()
						}
						dir('online_distribution') {
							deleteDir()
						}
						dir('acts') {
							deleteDir()
						}
						dir('macros')
						{
							deleteDir()
    						}	
						dir('calibrations')
						{
							deleteDir()
    						}	
						dir('tutorials')
						{
							deleteDir()
    						}
						dir('prototype')
						{
							deleteDir()
    						}
						dir('report')
						{
							deleteDir()
    						}
						sh('rm -fv *.*')
					
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
							  	]]
								] //checkout
							)//checkout
						}
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
									[name: "${sha_acts}"]
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

						//dir('macros')
						//{
						//	git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/macros.git'
    				//}	
						dir('calibrations')
						{
							// git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/calibrations.git'
							
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
							    	[name: "${sha_calibrations}"]
							    ], 
							  	userRemoteConfigs: 
							  	[[
							    	//credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
							     	credentialsId: 'sPHENIX-bot', 
							     	url: 'https://github.com/sPHENIX-Collaboration/calibrations.git',
							     	refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
							    	branch: ('*')
							  	]]
								] //checkout
							)//checkout
							
    				}	
						dir('prototype')
						{
							git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/prototype.git'
    				}
						dir('tutorials')
						{
							git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/tutorials.git'
    				}
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
					when {
    				// case insensitive regular expression for truthy values
						expression { return run_cppcheck ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
					}
					steps 
					{
		
		    		build(job: 'cpp-check-pipeline',
		    			parameters:
		    			[
		    				string(name: 'sha_coresoftware', value: "${sha_coresoftware}"), 		    				
		    				string(name: 'git_url_coresoftware', value: "${git_url_coresoftware}"), 		    
		    				string(name: 'mergeTarget_coresoftware', value: "${mergeTarget_coresoftware}"), 		    				
								string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
			    			string(name: 'upstream_build_description', value: "${upstream_build_description} / ${env.JOB_NAME}.#${env.BUILD_NUMBER}")
			    		],
		    			wait: false, propagate: false)
		   		}
				}// Stage - cpp check
				 
				
			// hold this until jenkins supports nested parallel 
			//	stage('Build-Test') {
			//		stages{
					    
						stage('sPHENIX-Build')
						{
							
							steps 
							{
								dir('build') {
									deleteDir()
								}
								sh('hostname')
								sh('pwd')
								sh('env')
								sh('ls -lvhc')
										
								sh('$singularity_exec_sphenix_farm3 sh utilities/jenkins/built-test/full-build.sh')
							
							 	script {
							  	build_root_path = pwd();
							 	}
										
							}										
						} // 				stage('sPHENIX-Build')
						
						
						stage('Test')
						{
							parallel {
									
								stage('test-default-detector-sPHENIX')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_default_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{			    		
										script
										{
											runCheckTest('test-default-detector-pipeline')
										}// script
									}				
								} // stage('test-default-detector-sPHENIX')
								
								
								stage('test-overlap-check-sPHENIX')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_default_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{			    		
										script
										{
											runCheckTest('test-overlap-check-pipeline')
										}// script
									}				
								} // stage('test-overlap-check-sPHENIX')
								
								
								
								stage('test-default-valgrind')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_valgrind_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{												    		
										script
										{
											runCheckTest('test-default-detector-valgrind-pipeline')
										}						   				    
									}				
								}
								
								stage('test-DST-readback')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_DST_readback ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{
												    		
										script
										{
											runCheckTest('test-DST-readback')
										}
						   				    
									}				
								}

								//---------------------------
								// Calo Production Year 2
								//---------------------------
								
								stage('test-default-CaloProduction-Fun4All_Year2')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_default_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{			    		
										script
										{
											runCheckTest('test-default-CaloProduction-Fun4All_Year2')		
										}// script
									}				
								} // stage('test-default-CaloProduction-Year2')
								stage('test-default-valgrind-CaloProduction-Year2')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_valgrind_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{												    		
										script
										{
											runCheckTest('test-default-valgrind-CaloProduction-Year2')	
										}						   				    
									}				
								}

								//---------------------------
								// Tracking Production StreamingProduction
								//---------------------------
								
								stage('test-default-StreamingProduction')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_default_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{			    		
										script
										{
											runCheckTest('test-default-StreamingProduction')		
										}// script
									}				
								} // stage('test-default-StreamingProduction')
								stage('test-default-valgrind-StreamingProduction')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_valgrind_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{												    		
										script
										{
											runCheckTest('test-default-valgrind-StreamingProduction')	
										}						   				    
									}				
								}

								stage('test-calo-single-qa')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_calo_qa ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{
										script
										{
											runCheckTest('test-calo-single-qa')	
										}
									}				
								}// 				stage('test-calo-single-qa')
								stage('test-tracking-reconstruction-prdf')
								{
									when
									{
										expression { return run_calo_qa ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps
									{
										script
										{
											runCheckTest('test-tracking-reconstruction-prdf')
										}
									}
								} // stage('test-tracking-reconstruction-prdf')
								stage('test-tracking-low-occupancy-qa')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_calo_qa ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
										// expression { return false } // temp disable this stage
									}
									steps 
									{
										script
										{
											runCheckTest('test-tracking-low-occupancy-qa')	
										} // script
									
						    		
										sh('ls -lhv')
						   			
									}//steps				
								}// 				stage('test-tracking-low-occupancy-qa')
															
							
								stage('test-tracking-distortions-qa')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_calo_qa ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
										// expression { return false } // temp disable this stage
									}
									steps 
									{
										script
										{
											runCheckTest('test-tracking-distortions-qa')	
										} // script
									
						    		
										sh('ls -lhv')
						   			
									}//steps				
								}// 				stage('test-tracking-distortions-qa')
															
								stage('test-tracking-pythiajet-qa')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_calo_qa ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
										// expression { return false } // temp disable this stage
									}
									steps 
									{
										script
										{
											runCheckTest('test-tracking-pythiajet-qa')	
										}
										sh('ls -lhv')
									}				
								}// 				stage('test-tracking-pythiajet-qa')
							}// parallel			
						}// stage - Test
		
					//}				//stages("Build-Test")
			//	}				 // stage("Build-Test")
			//} // parallel {
		//}//stage('Build')
		
	}//stages
		
	post {
		always{
		  
	                script {			
	                	
				if ("$build_type" == 'clang') {
					recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 1, tool: clang(pattern: 'build/${build_type}/rebuild.log')
				} else if ("$build_type" == 'scan') {
					recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 1, tool: clangAnalyzer(pattern: 'build/${build_type}/scanlog/*/*.plist')
				} else {
					recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 1, tool: gcc(pattern: 'build/${build_type}/rebuild.log')
				}
        		} // script 
			
			dir('report')
			{
				sh('ls -lvhc')
			  	
				script
				{					
					echo("start report building ...");
					sh ('pwd');						
				
					def report_content = "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) Build with configuration of `${system_config}` / `${build_type}` [is ${currentBuild.currentResult}](${env.BUILD_URL})";	        
	        				
					if ("$build_type" == 'clang') {
						report_content = "${report_content}, [:bar_chart:clang report (full)](${env.BUILD_URL}/clang/)/[(new)](${env.BUILD_URL}/clang/new/)";
					} else if ("$build_type" == 'scan') {
						report_content = "${report_content}, [:bar_chart:scan-build report (full)](${env.BUILD_URL}/clang-analyzer/)/[(new)](${env.BUILD_URL}/clang-analyzer/new/)";
					} else {
						report_content = "${report_content}, [:bar_chart:Compiler report (full)](${env.BUILD_URL}/gcc/)/[(new)](${env.BUILD_URL}/gcc/new/)";
					}
					
					report_content = "${report_content}, [build log](${env.BUILD_URL}/artifact/build/${build_type}/rebuild.log)"
					
					def files = findFiles(glob: '*.md')
					echo("all reports: $files");
					// def testFileNames = files.split('\n')
					for (def fileEntry : files) 
					{    			
						String file = fileEntry.path;    				

						//String fileContent = readFile(file);

						//echo("$file  -> ${fileContent}");
						
						def lines = readFile(file).split('\n')
						
						for (def line : lines){
						
							String fileContent = line;
							echo("$file  -> |${fileContent}|");
						    						    
							// update report summary
							report_content = "${report_content}\n  ${fileContent}"		//nested list for child reports

							// update build description
							// currentBuild.description = "${currentBuild.description}\n${fileContent}"		
						}
						
	
					}    			

					writeFile file: "build-${system_config}-${build_type}.md", text: "${report_content}"	
										
					build(job: 'github-commit-checkrun',
						parameters:
						[
							string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
							string(name: 'src_Job_id', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
							string(name: 'src_details_url', value: "${env.BUILD_URL}"),
							string(name: 'checkrun_status', value: "completed"),
							string(name: 'checkrun_conclusion', value: "${currentBuild.currentResult}"),
							string(name: 'output_title', value: "sPHENIX Jenkins Report for ${env.JOB_NAME}"),
							string(name: 'output_summary', value: "[![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) Build with configuration of `${system_config}` / `${build_type}` [is ${currentBuild.currentResult}](${env.BUILD_URL})"),
							string(name: 'output_text', value: "${currentBuild.displayName}\n\n${currentBuild.description}")
						],
						wait: false, propagate: false
					) // build(job: 'github-commit-checkrun',
								
				}//script
		  	} //dir('report')
			
			archiveArtifacts artifacts: "report/build-${system_config}-${build_type}.md"
		
			archiveArtifacts artifacts: "build/${build_type}/rebuild.log"
		} // always
	
	}
	
}//pipeline 


def runCheckTest(String jobname) 
{    
	def built = build(job: jobname,
		parameters:
		[
			string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
			string(name: 'singularity_cmd', value: "${singularity_cmd}"), 
			string(name: 'build_src', value: "${build_root_path}"), 
			string(name: 'build_type', value: "${build_type}"), 
			string(name: 'system_config', value: "${system_config}"), 
			string(name: 'sha_macros', value: "${sha_macros}"), 
			string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
			string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
		],
		wait: true, propagate: false)

	copyArtifacts(projectName: jobname, selector: specific("${built.number}"), filter: 'report/*.md');

	if ("${built.result}" != 'SUCCESS' && "${built.result}" != 'UNSTABLE')
	{
		error(jobname + ': FAIL')
	} 
}

