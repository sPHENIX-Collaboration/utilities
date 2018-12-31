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
					
						sh('hostname')
						sh('pwd')
						sh('env')
						sh('ls -lvhc')

						dir('utilities/jenkins/built-test/') {
							
							sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f singularity-check.sh')
						
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
		
		    		build(job: 'cpp-check',
		    			parameters:
		    			[
		    				string(name: 'coresoftware_src', value: "${WORKSPACE}/coresoftware"), 
			    			string(name: 'upstream_build_description', value: "${currentBuild.description}")
			    		],
		    			wait: true, propagate: false)
		    			
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
				    						string(name: 'upstream_build_description', value: "${currentBuild.description}")
			    						],
						    			wait: true, propagate: true)
						   										
						   				copyArtifacts(projectName: 'Build-Master', filter: 'qa_page.tar.gz', selector: specific("${built.number}"));
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
							
			} // parallel {
		}//stage('Build')
		
	}//stages
		
	post {
		//always{
			// archiveArtifacts artifacts: 'build/new/rebuild.log'
		//}
	
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

