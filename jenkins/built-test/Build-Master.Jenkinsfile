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
						
						slackSend (color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
										
						build(job: 'github-comment-label',
		    			parameters:
		    			[
		    				string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
			    			string(name: 'LabelCategory', value: "build-${system_config}-${build_type}"),
			    			string(name: 'LabelStatus', value: "PENDING")
			    		],
		    			wait: false, propagate: false)
						
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

						dir('utilities/jenkins/built-test/') {
							
							sh('$singularity_exec_sphenix tcsh -f singularity-check.sh ${build_type}')
						
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
										
								sh('$singularity_exec_sphenix  sh utilities/jenkins/built-test/full-build.sh')
							
							 	script {
							  	build_root_path = pwd();
							 	}
										
								slackSend (color: '#00F000', message: "sPHENIX build available: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}). Buld available at ${build_root_path}")
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
											def built = build(job: 'test-default-detector-pipeline',
												parameters:
												[
													string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
													string(name: 'build_src', value: "${build_root_path}"), 
													string(name: 'build_type', value: "${build_type}"), 
													string(name: 'system_config', value: "${system_config}"), 
													string(name: 'sha_macros', value: "${sha_macros}"), 
													string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
													string(name: 'detector_name', value: "sPHENIX"), 
													string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
												],
												wait: true, propagate: false)

											copyArtifacts(projectName: 'test-default-detector-pipeline', selector: specific("${built.number}"), filter: 'report/*.md');

											if ("${built.result}" != 'SUCCESS')
											{
												error('test-default-detector-sPHENIX FAIL')
											}							
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
											def built = build(job: 'test-overlap-check-pipeline',
												parameters:
												[
													string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
													string(name: 'build_src', value: "${build_root_path}"), 
													string(name: 'build_type', value: "${build_type}"), 
													string(name: 'system_config', value: "${system_config}"), 
													string(name: 'sha_macros', value: "${sha_macros}"), 
													string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
													string(name: 'detector_name', value: "sPHENIX"), 
													string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
												],
												wait: true, propagate: false)

											copyArtifacts(projectName: 'test-overlap-check-pipeline', selector: specific("${built.number}"), filter: 'report/*.md');

											if ("${built.result}" != 'SUCCESS')
											{
												error('test-overlap-check-sPHENIX FAIL')
											}							
										}// script
									}				
								} // stage('test-overlap-check-sPHENIX')
								
								stage('test-default-detector-fsPHENIX')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_default_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ } // temp assignment to QA switch. Move to run_default_test switch later
									}
									steps 
									{			    		
										script
										{
				   						def built = build(job: 'test-default-detector-pipeline',
						    			parameters:
						    			[
							    			string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
										string(name: 'build_src', value: "${build_root_path}"), 
							    			string(name: 'build_type', value: "${build_type}"), 
							    			string(name: 'system_config', value: "${system_config}"), 
							    			string(name: 'sha_macros', value: "${sha_macros}"), 
		    								string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
		    								string(name: 'detector_name', value: "fsPHENIX"), 
				    						string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
			    						],
						    			wait: true, propagate: false)
						   										
						   				copyArtifacts(projectName: 'test-default-detector-pipeline', selector: specific("${built.number}"), filter: 'report/*.md');
						   				if ("${built.result}" != 'SUCCESS')
						   				{
						   					error('test-default-detector-fsPHENIX FAIL')
    									}							
										}
						   			
						   				    
									}								
								}// 				stage('test-default-detector-fsPHENIX')
								
								stage('test-default-detector-EICDetector')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_default_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ } // temp assignment to QA switch. Move to run_default_test switch later
									}
									steps 
									{			    		
										script
										{
				   						def built = build(job: 'test-default-detector-pipeline',
						    			parameters:
						    			[
							    			string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
										string(name: 'build_src', value: "${build_root_path}"), 
							    			string(name: 'build_type', value: "${build_type}"), 
							    			string(name: 'system_config', value: "${system_config}"), 
							    			string(name: 'sha_macros', value: "${sha_macros}"), 
		    								string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
		    								string(name: 'detector_name', value: "EICDetector"), 
				    						string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
			    						],
						    			wait: true, propagate: false)
						   										
						   				copyArtifacts(projectName: 'test-default-detector-pipeline', selector: specific("${built.number}"), filter: 'report/*.md');
						   				if ("${built.result}" != 'SUCCESS')
						   				{
						   					error('test-default-detector-EICDetector FAIL')
    									}							
										}
						   				    
									}								
								}// 				stage('test-default-detector-EICDetector')
								
								
								stage('test-default-valgrind')
								{
									
									when {
				    				// case insensitive regular expression for truthy values
										expression { return run_valgrind_test ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{
										//sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-default.sh')
												    		
										script
										{
											def built = build(job: 'test-default-detector-valgrind-pipeline',
												parameters:
												[
													string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
													string(name: 'build_src', value: "${build_root_path}"), 
													string(name: 'build_type', value: "${build_type}"), 
													string(name: 'system_config', value: "${system_config}"), 
													string(name: 'sha_macros', value: "${sha_macros}"), 
													string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
													string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
												],
												wait: true, propagate: false)

											copyArtifacts(projectName: 'test-default-detector-valgrind-pipeline', selector: specific("${built.number}"));

											if ("${built.getResult()}" == 'FAILURE')
											{
												currentBuild.result = "${built.getResult()}"
												error("test-default-detector-valgrind-pipeline #${built.number} ${built.getResult()}");
											}
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
										//sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-default.sh')
												    		
										script
										{
											def built = build(job: 'test-DST-readback',
												parameters:
												[
													string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
													string(name: 'build_src', value: "${build_root_path}"), 
													string(name: 'build_type', value: "${build_type}"), 
													string(name: 'system_config', value: "${system_config}"), 
													string(name: 'sha_macros', value: "${sha_macros}"), 
													string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
													string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
												],
												wait: true, propagate: false)

											copyArtifacts(projectName: 'test-DST-readback', selector: specific("${built.number}"));
						   				if ("${built.result}" != 'SUCCESS')
						   				{
						   					error('test-DST-readback FAIL')
    									}								

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
				   						def built = build(job: 'test-calo-single-qa',
							    			parameters:
							    			[
								    			string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
											string(name: 'build_src', value: "${build_root_path}"), 
							    				string(name: 'build_type', value: "${build_type}"), 
							    				string(name: 'system_config', value: "${system_config}"), 
							    				string(name: 'sha_macros', value: "${sha_macros}"), 
		    									string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
				    							string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
			    							],
							    			wait: true, propagate: false)
						   			
						   				  copyArtifacts(projectName: 'test-calo-single-qa', selector: specific("${built.number}"));
						   				  
						   				if ("${built.result}" != 'SUCCESS')
						   				{
						   					error('test-calo-single-qa FAIL')
    									}								
										}
										// archiveArtifacts artifacts: 'qa_page.tar.gz'
										
						    		
										sh('ls -lhv')
						   			
						   			//dir('macros/macros/g4simulations/')
						   			//{
						   			//	stash name: "test-calo-single-qa-stash", includes: "*"
						   			//}
						   			
						   			//dir('test-calo-single-qa-output')
						   			//{
						   			//	unstash "test-calo-single-qa-stash"
						   			//	archiveArtifacts artifacts: '*', onlyIfSuccessful: true	
						   			//}    		   			
						   			
										//dir('qa_html')
										//{
						    		//	sh ("tar xzfv ../qa_page.tar.gz")
										//}
				
									  //publishHTML (target: [
								    //  allowMissing: false,
								    //  alwaysLinkToLastBuild: false,
								    //  keepAll: true,
								    //  reportDir: 'qa_html',
								    //  reportFiles: 'index.html',
								    //  reportName: "Calorimeter QA Report"
								    //])
							   			
									}				
								}// 				stage('test-calo-single-qa')
								
								
							
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
				   						def built = build(job: 'test-tracking-low-occupancy-qa',
											parameters:
											[
												string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
												string(name: 'build_src', value: "${build_root_path}"), 
												string(name: 'build_type', value: "${build_type}"), 
												string(name: 'system_config', value: "${system_config}"), 
												string(name: 'sha_macros', value: "${sha_macros}"), 
												string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
												string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
											],
											wait: true, propagate: false)
						   			
						   				  copyArtifacts(projectName: 'test-tracking-low-occupancy-qa', selector: specific("${built.number}"));
						   				  
						   				if ("${built.result}" != 'SUCCESS')
						   				{
						   					error('test-tracking-low-occupancy-qa FAIL')
    									}								
										}
										// archiveArtifacts artifacts: 'qa_page.tar.gz'
										
						    		
										sh('ls -lhv')
						   			
						   			//dir('macros/macros/g4simulations/')
						   			//{
						   			//	stash name: "test-calo-single-qa-stash", includes: "*"
						   			//}
						   			
						   			//dir('test-calo-single-qa-output')
						   			//{
						   			//	unstash "test-calo-single-qa-stash"
						   			//	archiveArtifacts artifacts: '*', onlyIfSuccessful: true	
						   			//}    		   			
						   			
										//dir('qa_html')
										//{
						    		//	sh ("tar xzfv ../qa_page.tar.gz")
										//}
				
									  //publishHTML (target: [
								    //  allowMissing: false,
								    //  alwaysLinkToLastBuild: false,
								    //  keepAll: true,
								    //  reportDir: 'qa_html',
								    //  reportFiles: 'index.html',
								    //  reportName: "Calorimeter QA Report"
								    //])
							   			
									}				
								}// 				stage('test-tracking-low-occupancy-qa')
							
								stage('test-tracking-high-occupancy-qa')
								{
									
									when {
				    						// case insensitive regular expression for truthy values
										expression { return run_calo_qa ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
									}
									steps 
									{
										script
										{
											def built = build(job: 'test-tracking-high-occupancy-qa',
											parameters:
											[
												string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
												string(name: 'build_src', value: "${build_root_path}"), 
												string(name: 'build_type', value: "${build_type}"), 
												string(name: 'system_config', value: "${system_config}"), 
												string(name: 'sha_macros', value: "${sha_macros}"), 
												string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
												string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
											],
											wait: true, propagate: false)

											  copyArtifacts(projectName: 'test-tracking-high-occupancy-qa', selector: specific("${built.number}"));

											if ("${built.result}" != 'SUCCESS')
											{
												error('test-tracking-high-occupancy-qa FAIL')
											}								
										}
										// archiveArtifacts artifacts: 'qa_page.tar.gz'										
						    		
										sh('ls -lhv')
						   			
									}				
								}// 				stage('test-tracking-high-occupancy-qa')
								
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
					recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 100, tool: clang(pattern: 'build/${build_type}/rebuild.log')
				} else if ("$build_type" == 'scan') {
					recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 100, tool: clangAnalyzer(pattern: 'build/${build_type}/scanlog/*/*.plist')
				} else {
					recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 100, tool: gcc(pattern: 'build/${build_type}/rebuild.log')
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
							currentBuild.description = "${currentBuild.description}\n${fileContent}"		
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
		
			archiveArtifacts artifacts: 'build/${build_type}/rebuild.log'
			
			
			
		} // always
	
		success {
		
			build(job: 'github-comment-label',
			  parameters:
			  [
					string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
					string(name: 'LabelCategory', value: "build-${system_config}-${build_type}"),
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
					string(name: 'LabelCategory', value: "build-${system_config}-${build_type}"),
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
					string(name: 'LabelCategory', value: "build-${system_config}-${build_type}"),
					string(name: 'LabelStatus', value: "PASS")
				],
				wait: false, propagate: false)
				
			slackSend (color: '#FFF000', message: "UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
	}
	
}//pipeline 

