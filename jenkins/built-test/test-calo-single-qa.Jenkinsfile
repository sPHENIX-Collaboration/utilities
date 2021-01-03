pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
    options {
        timeout(time: 10, unit: 'HOURS') 
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
			    			string(name: 'LabelCategory', value: "calo-QA"),
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
						dir('QA-gallery')
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
							
							sh('$singularity_exec_sphenix tcsh singularity-check.sh ${build_type}')
						
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
							  				mergeTarget: 'QA-calorimeter-single-particle'
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
    				
				
						dir('QA-gallery')
						{			
							
							checkout(
								[
						 			$class: 'GitSCM',
						   		extensions: [               
							   		[$class: 'CleanCheckout'],  
						   		],
							  	branches: [
							    		[name: "${sha_QA_gallery}"]
							    	], 
							  	userRemoteConfigs: 
							  	[[
							     	credentialsId: 'sPHENIX-bot', 
							     	url: '${git_url_QA_gallery}',
							     	refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/main:refs/remotes/origin/main'), 
							    	branch: ('*')
							  	]]
								] //checkout
							)//checkout
							
    						}	
						
					}
				}
			}
		}//stage('SCM Checkout')
		
		stage('Copy reference')
		{
			
			steps 
			{
				timestamps { 
					ansiColor('xterm') {
						
						dir('reference')
						{
    					copyArtifacts(projectName: "test-calo-single-qa-reference", selector: lastSuccessful());

							sh('ls -lvhc')
    				}
						
					}
				}
			}
		}//stage('SCM Checkout')
		
		stage('Test-e-')
		{
			
			
			steps 
			{
					
				sh('$singularity_exec_sphenix sh utilities/jenkins/built-test/test-calo-single-qa.sh e- 4 15')
														
			}				
					
		}
		stage('Test-pi+')
		{
			
			
			steps 
			{
					
				sh('$singularity_exec_sphenix sh utilities/jenkins/built-test/test-calo-single-qa.sh pi+ 30 15')
				
				archiveArtifacts artifacts: 'macros/macros/QA/calorimeter/G4sPHENIX_*_Sum*_qa.root*'										
			}				
					
		}
		
		stage('html-report')
		{
			steps 
			{
			
			
				script{
			    def built = build(job: 'test-calo-single-qa-gallery',
			    	parameters:
			    	[
			    		string(name: 'build_src', value: "${env.JOB_NAME}"),
			    		string(name: 'src_build_id', value: "${env.BUILD_NUMBER}"), 
			  			string(name: 'upstream_build_description', value: "${upstream_build_description} / <a href=\"${env.JOB_URL}\">${env.JOB_NAME}</a>.<a href=\"${env.BUILD_URL}\">#${env.BUILD_NUMBER}</a>")
			  		],
			    	wait: true, propagate: true)	
				  
				  copyArtifacts(projectName: 'test-calo-single-qa-gallery', selector: specific("${built.number}"));
				}
				
				
				dir('qa_html')
				{
					sh('ls -lhv')
				
					archiveArtifacts artifacts: 'qa_page.tar.gz'
					
    			sh ("tar xzfv ./qa_page.tar.gz")
    			
					sh('ls -lhv')
				}

				  publishHTML (target: [
			      allowMissing: false,
			      alwaysLinkToLastBuild: false,
			      keepAll: true,
			      reportDir: 'qa_html',
			      reportFiles: 'index.html',
			      reportName: "QA Report"
			    ])
			}			// steps	
					
		}
		
	}//stages

	
	post {
	
		always{
		  
			dir('report')
			{
			//  writeFile file: "QA-calo.md", text: "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) Calorimeter QA: [build is ${currentBuild.currentResult}](${env.BUILD_URL}), [:bar_chart:QA report - Calorimeter](${env.BUILD_URL}/QA_20Report/) "				
			
				script
				{					
					echo("start report building ...");
					sh ('pwd');						
				
					def report_content = "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) Calorimeter QA: [build is ${currentBuild.currentResult}](${env.BUILD_URL})";	        
	        				
					def files = findFiles(glob: '../QA-gallery/report*.md')
					echo("all reports: $files");
					// def testFileNames = files.split('\n')
					for (def fileEntry : files) 
					{    			
						String file = fileEntry.path;    				

						String fileContent = readFile(file).trim();

						echo("$file  -> ${fileContent}");

						// update report summary
						report_content = "${report_content}\n  ${fileContent}"		//nested list for child reports

						// update build description
						currentBuild.description = "${currentBuild.description}\n${fileContent}"		
					}    			

					writeFile file: "QA-calo.md", text: "${report_content}"	
				
				}//script
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
					string(name: 'output_summary', value: "* [![Build Status ](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) Calorimeter QA: [build is ${currentBuild.currentResult}](${env.BUILD_URL})"),
					string(name: 'output_text', value: "${currentBuild.displayName}\n\n${currentBuild.description}")
				],
				wait: false, propagate: false
			) // build(job: 'github-commit-checkrun',
		}

		success {
			script {
				currentBuild.description = "${upstream_build_description}<br><button onclick=\"window.location.href='${JENKINS_URL}/job/sPHENIX/job/test-calo-single-qa-reference/parambuild/?ref_build_id=${BUILD_ID}';\">Use as QA reference</button>"  
			}
			
			build(job: 'github-comment-label',
			  parameters:
			  [
					string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
					string(name: 'LabelCategory', value: "calo-QA"),
					string(name: 'LabelStatus', value: "AVAILABLE")
				],
				wait: false, propagate: false)
				
			slackSend (color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
		failure {
			build(job: 'github-comment-label',
			  parameters:
			  [
					string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
					string(name: 'LabelCategory', value: "calo-QA"),
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
					string(name: 'LabelCategory', value: "calo-QA"),
					string(name: 'LabelStatus', value: "AVAILABLE")
				],
				wait: false, propagate: false)
			slackSend (color: '#FFF000', message: "UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
	}
}//pipeline 

