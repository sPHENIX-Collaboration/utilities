pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
       
	stages { 
		stage('Initialize') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
						
						slackSend (color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
															
						dir('coresoftware') {
							deleteDir()
						}			
						dir('qa_html') {
							deleteDir()
						}			
						dir('report') {
							// deleteDir()
						}
					
						sh('hostname')
						sh('pwd')
						sh('env')
						sh('ls -lvhc')

						dir('utilities/jenkins/built-test/') {
							
							sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f singularity-check.sh')
						
						}
												
						script
						{
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${sha1}"
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
				                //credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Test/coresoftware.git'
				                credentialsId: 'sPHENIX-bot', 
				                url: 'https://github.com/sPHENIX-Test/coresoftware.git',
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
				   		def built = build(job: 'cpp-check',
			    			parameters:
			    			[
			    				string(name: 'coresoftware_src', value: "${WORKSPACE}/coresoftware"), 
				    			string(name: 'upstream_build_description', value: "${currentBuild.description}"),
					    		string(name: 'ghprbPullLink', value: "${ghprbPullLink}")
				    		],
			    			wait: true, propagate: false)
			    			
						   copyArtifacts(projectName: 'cpp-check', filter: 'report/*', selector: specific("${built.number}"));
		    		}
		   		}
				}// Stage - cpp check
				 
				
			// hold this until jenkins supports nested parallel 
			stage('Build-Test') {
			
									steps 
									{
										//sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-default.sh')
												    		
										script
										{
				   						def built = build(job: 'Build-Master',
						    			parameters:
						    			[
							    			string(name: 'sha_coresoftware', value: "${sha1}"), 
							    			string(name: 'git_url_coresoftware', value: "https://github.com/sPHENIX-Test/coresoftware.git"), 
							    			booleanParam(name: 'run_cppcheck', value: false), 
				    						string(name: 'upstream_build_description', value: "${currentBuild.description}"), 
				    						string(name: 'ghprbPullLink', value: "${ghprbPullLink}")
			    						],
						    			wait: true, propagate: true)
						   										
						   				copyArtifacts(projectName: 'Build-Master', filter: 'qa_page.tar.gz', selector: specific("${built.number}"));
						   				copyArtifacts(projectName: 'Build-Master', filter: 'report/*', selector: specific("${built.number}"));
										}
						   			
										dir('qa_html')
										{
											sh('ls -lhv')
																					
						    			sh ("tar xzfv ../qa_page.tar.gz")
						    			
											sh('ls -lhv')
										}
						
									  publishHTML (target: [
								      allowMissing: false,
								      alwaysLinkToLastBuild: false,
								      keepAll: true,
								      reportDir: 'qa_html',
								      reportFiles: 'index.html',
								      reportName: "Calorimeter QA Report"
								    ])
						   				    
									}				// steps
				}//stage('Build-Test')
				
			// hold this until jenkins supports nested parallel 
			stage('Build-Test-ROOT6') {
			
									steps 
									{
										//sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-default.sh')
												    		
										script
										{
				   						def built = build(job: 'Build-Master',
						    			parameters:
						    			[
							    			string(name: 'sha_coresoftware', value: "${sha1}"), 
							    			string(name: 'git_url_coresoftware', value: "https://github.com/sPHENIX-Test/coresoftware.git"), 
							    			string(name: 'mergeTarget_coresoftware', value: "new-genfit"), 
							    			string(name: 'build_type', value: "root6"), 
							    			booleanParam(name: 'run_cppcheck', value: false), 
							    			booleanParam(name: 'run_default_test', value: false), 
							    			booleanParam(name: 'run_calo_qa', value: false), 
				    						string(name: 'upstream_build_description', value: "${currentBuild.description}"), 
				    						string(name: 'ghprbPullLink', value: "${ghprbPullLink}")
			    						],
						    			wait: true, propagate: true)						 
						   				copyArtifacts(projectName: 'Build-Master', filter: 'report/*', selector: specific("${built.number}"));  										
										}						   			
						   				    
									}				// steps
				}//stage('Build-Test')
							
			} // parallel {
		}//stage('Build')
		
	}//stages
		
	post {
		always{
			// archiveArtifacts artifacts: 'build/new/rebuild.log'
			
			dir('report')
			{
				script
				{
					
    			echo("start report building ...");
				
					def report_content = """
## Pull request test report
* [pull request build overall is ${currentBuild.currentResult}](${env.BUILD_URL}).
"""
				
    			def files = findFiles(glob: '*.md')
    			echo("all reports: $files");
    			// def testFileNames = files.split('\n')
    			for (def fileEntry : files) 
    			{    			
    				String file = fileEntry.path;    				
    				
    				String fileContent = readFile(file).trim();
    				
    				echo("$file  -> ${fileContent}");
    				
    				report_content = "${report_content}\n${fileContent}"		
    			}
    			
				}// script
				
		
				
			  writeFile file: "summary.md", text: "$report_content"		
			}
			
			archiveArtifacts artifacts: 'report/*.md'
			
			build(job: 'github-comment-label',
				  parameters:
				  [
						string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
						string(name: 'LabelCategory', value: ""),
						string(name: 'githubComment', value: "${report_content}")
					],
					wait: false, propagate: false)
		}
	
		success {
			slackSend (color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
		failure {
			slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
		unstable {
			slackSend (color: '#FFF000', message: "UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
	}
	
}//pipeline 

