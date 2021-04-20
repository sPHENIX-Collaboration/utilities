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
								
						dir('coresoftware') {
							deleteDir()
						}			
						dir('qa_html') {
							deleteDir()
						}			
						dir('report') {
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
		
		// hold this until jenkins supports nested parallel
		stage('Build')
		{
			parallel {
			
				stage('cpp-check')
				{
					when {
    			 	// case insensitive regular expression for truthy values
						expression { return run_cppcheck ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
					}
					steps 
					{
						echo ("starting cpp-check with run_cppcheck = ${run_cppcheck}")
		
						script
						{
				   		def built = build(job: 'cpp-check-pipeline',
			    			parameters:
			    			[
							string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
							string(name: 'sha_coresoftware', value: "${sha1}"), 
							string(name: 'git_url_coresoftware', value: "https://github.com/${ghprbGhRepository}.git"), 
				    			string(name: 'upstream_build_description', value: "${currentBuild.description}"),
					    		string(name: 'ghprbPullLink', value: "${ghprbPullLink}")
				    		],
			    			wait: true, propagate: false)
			    			
						copyArtifacts(projectName: 'cpp-check-pipeline', filter: 'report/*', selector: specific("${built.number}"));
		    		
						if ("${built.result}" != 'SUCCESS')
						{
						   error('Build New FAIL by cppcheck')
    						}
					}
		   		}
				}// Stage - cpp check
				 
				
				
			// hold this until jenkins supports nested parallel 
			//stage('Build-Test-ROOT6') {
			//
			//						steps 
			//						{
			//							//sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-default.sh')
			//									    		
			//							script
			//							{
			//	   						def built = build(job: 'Build-Master',
			//			    			parameters:
			//			    			[
			//				    			string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
			//							string(name: 'sha_coresoftware', value: "${sha1}"), 
			//				    			string(name: 'git_url_coresoftware', value: "https://github.com/${ghprbGhRepository}.git"), 
			//				    			string(name: 'build_type', value: "root6"), 
			//				    			booleanParam(name: 'run_cppcheck', value: false), 
			//				    			booleanParam(name: 'run_default_test', value: true), 
			//				    			booleanParam(name: 'run_calo_qa', value: false), 
			//	    						string(name: 'upstream_build_description', value: "${currentBuild.description}"), 
			//	    						string(name: 'ghprbPullLink', value: "${ghprbPullLink}")
			//    						],
			//			    			wait: true, propagate: true)						 
			//			   				copyArtifacts(projectName: 'Build-Master', filter: 'report/*', selector: specific("${built.number}"));  										
			//							}						   			
			//			   				    
			//						}				// steps
			//	}//stage('Build-Test')
			// hold this until jenkins supports nested parallel 

			stage('Build-Test-gcc8') {
			
									steps 
									{
											    		
										script
										{
				   						def built = build(job: 'Build-Master-gcc8',
						    			parameters:
						    			[
							    			string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
										string(name: 'sha_coresoftware', value: "${sha1}"), 
							    			string(name: 'git_url_coresoftware', value: "https://github.com/${ghprbGhRepository}.git"), 
							    			string(name: 'build_type', value: "new"), 
							    			string(name: 'system_config', value: "gcc-8.3"), 
							    			booleanParam(name: 'run_cppcheck', value: false), 
							    			booleanParam(name: 'run_default_test', value: true), 
							    			booleanParam(name: 'run_valgrind_test', value: true), 
							    			booleanParam(name: 'run_calo_qa', value: true), 
							    			booleanParam(name: 'run_DST_readback', value: true), 
				    						string(name: 'upstream_build_description', value: "${currentBuild.description}"), 
				    						string(name: 'ghprbPullLink', value: "${ghprbPullLink}")
			    						],
						    			wait: true, propagate: false)						 
						   				copyArtifacts(projectName: 'Build-Master-gcc8', filter: 'report/*', selector: specific("${built.number}"));  							
						   				if ("${built.result}" != 'SUCCESS')
						   				{
						   					error('Build gcc-8.3 FAIL')
    									}								
										}						   			
						   				    
									}				// steps
				}//stage('Build-Test')
				
			stage('Build-Test-Clang') {
			
									steps 
									{
										//sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-default.sh')
												    		
										script
										{
											def built = build(job: 'Build-Clang',
											parameters:
											[
												string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
												string(name: 'sha_coresoftware', value: "${sha1}"), 
												string(name: 'git_url_coresoftware', value: "https://github.com/${ghprbGhRepository}.git"), 
												booleanParam(name: 'run_valgrind_test', value: false), 
												booleanParam(name: 'run_default_test', value: false), 
												booleanParam(name: 'run_DST_readback', value: false), 
												booleanParam(name: 'run_calo_qa', value: false), 
												string(name: 'upstream_build_description', value: "${currentBuild.description}"), 
												string(name: 'ghprbPullLink', value: "${ghprbPullLink}")
											],
											wait: true, propagate: false)						    									 
												copyArtifacts(projectName: 'Build-Clang', filter: 'report/*', selector: specific("${built.number}"));  		

											if ("${built.result}" != 'SUCCESS')
											{
												error('Build-Clang FAIL')
											}										
			
										}//script						   			
							   				    
									} // steps
				}//stage('Build-Test-Clang')
				stage('Build-Test-Scanbuild') {
			
									steps 
									{
												    		
										script
										{
				   						def built = build(job: 'Build-ScanBuild',
						    			parameters:
						    			[
							    			string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
										string(name: 'sha_coresoftware', value: "${sha1}"), 
							    			string(name: 'git_url_coresoftware', value: "https://github.com/${ghprbGhRepository}.git"), 
							    			booleanParam(name: 'run_DST_readback', value: false), 
							    			booleanParam(name: 'run_cppcheck', value: false), 
							    			booleanParam(name: 'run_default_test', value: false), 
							    			booleanParam(name: 'run_calo_qa', value: false), 
				    						string(name: 'upstream_build_description', value: "${currentBuild.description}"), 
				    						string(name: 'ghprbPullLink', value: "${ghprbPullLink}")
			    						],
						    			wait: true, propagate: false)						    									 
						   				copyArtifacts(projectName: 'Build-ScanBuild', filter: 'report/*', selector: specific("${built.number}"));  		
						   				
						   				if ("${built.result}" != 'SUCCESS')
						   				{
						   					// error('Build-ScanBuild FAIL')
    									}										
			
										}//script						   			
							   				    
									}				// steps
				}//stage('Build-Test-Scanbuild')
							
							
			} // parallel {
		}//stage('Build')
		
	}//stages
		
	post {
		always{
			// archiveArtifacts artifacts: 'build/new/rebuild.log'
			
			dir('report')
			{
				sh('ls -lvhc')
						
				script
				{
					
    			echo("start report building ...");
    			sh ('pwd');
				
			def report_content = """
## Build & test report 
Report for [commit ${ghprbActualCommit}](${ghprbPullLink}/commits/${ghprbActualCommit}):"""
				
			if ("${currentBuild.currentResult}" == "FAILURE")
			{
  				report_content = """${report_content}
[![Jenkins on fire](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_fire-128p.png)](${env.BUILD_URL})"""
			}
			if ("${currentBuild.currentResult}" == "ABORT")
			{
  				report_content = """${report_content}
[![Jenkins aborted](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_snow-128p.png)](${env.BUILD_URL})"""
			}
			if ("${currentBuild.currentResult}" == "SUCCESS")
			{
  				report_content = """${report_content}
[![Jenkins passed](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_pass-128p.png)](${env.BUILD_URL})"""
			}

  			report_content = """${report_content}
* [![Build Status](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) [builds and tests overall are ${currentBuild.currentResult}](${env.BUILD_URL})."""
				
    			def files = findFiles(glob: '*.md')
    			echo("all reports: $files");
    			// def testFileNames = files.split('\n')
    			for (def fileEntry : files) 
    			{    			
    				String file = fileEntry.path;    				
    				
    				String fileContent = readFile(file).trim();
    				
    				echo("$file  -> ${fileContent}");
    				
    				// update report summary
    				report_content = "${report_content}\n${fileContent}"		
    				
    				// update build description
    				currentBuild.description = "${currentBuild.description}\n${fileContent}"		
    			}    			
    			
  				report_content = """${report_content}

--------------------
_Automatically generated by [sPHENIX Jenkins continuous integration](${env.JOB_DISPLAY_URL})_
[![sPHENIX](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/sphenix-logo-white-bg-72p.png)](https://www.sphenix.bnl.gov/web/) &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; [![jenkins.io](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_title-72p.png)](https://jenkins.io/)"""
    			
			  	writeFile file: "summary.md", text: "${report_content}"		
			  	
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
			
			archiveArtifacts artifacts: 'report/*.md'
			
		}
	
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
