pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
    options {
        timeout(time: 2, unit: 'HOURS') 
    }
       
	stages { 
	
		stage('Prebuild-Cleanup') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
					
					
						build(job: 'github-comment-label',
		    			parameters:
		    			[
		    				string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
			    			string(name: 'LabelCategory', value: "track-low-occ-QA"),
			    			string(name: 'LabelStatus', value: "PENDING")
			    		],
		    			wait: false, propagate: false)
					
						script {
						
							currentBuild.description = "${upstream_build_description}" 
			
							if (fileExists('./install'))
							{
								sh "rm -frv ./install"
							}
							if (fileExists('./calibrations'))
							{
								sh "rm -frv ./calibrations"
							}						
							if (fileExists('./build'))
							{
								sh "rm -frv ./build"
							}						
							if (fileExists('./qa_html'))
							{
								sh "rm -fvr ./qa_html"
							}						
							if (fileExists('./report'))
							{
								sh "rm -frv ./report"
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
							
							sh('/usr/bin/singularity exec -B /cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg  tcsh -f singularity-check.sh ${build_type}')
						
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
							  			mergeTarget: 'tracking-low-occupancy-qa'
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
		
		stage('Copy reference')
		{
			
			when {
    			// case insensitive regular expression for truthy values
					expression { return use_reference ==~ /(?i)(Y|YES|T|TRUE|ON|RUN)/ }
			}
			steps 
			{
				timestamps { 
					ansiColor('xterm') {
						
						dir('macros/macros/QA/tracking/reference')
						{
    					copyArtifacts(projectName: "test-tracking-low-occupancy-qa-reference", selector: lastSuccessful());

							sh('ls -lvhc')
    				}
						
					}
				}
			}
		}//stage('SCM Checkout')
		
		stage('Test')
		{
			
			
			steps 
			{
					
				sh('/usr/bin/singularity exec -B /cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-tracking-low-occupancy-qa.sh $build_type $num_event $number_jobs')
				
				archiveArtifacts artifacts: 'macros/macros/QA/tracking/G4sPHENIX_*_Sum*_qa.root*'										
			}				
					
		}
		
		
		stage('html-report')
		{
			steps 
			{
			
				sh('sh utilities/jenkins/built-test/test-tracking-qa-gallery.sh')
			
				  publishHTML (target: [
			      allowMissing: false,
			      alwaysLinkToLastBuild: false,
			      keepAll: true,
			      reportDir: 'qa_html/_build/',
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
			  writeFile file: "tracking-low-occupancy-qa.md", text: "* [![Build Status ](https://web.racf.bnl.gov/jenkins-sphenix/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) Tracking QA at low occupancy: [build is ${currentBuild.currentResult}](${env.BUILD_URL}), [:bar_chart:QA report - Tracking](${env.BUILD_URL}/QA_20Report/) "				
			}
		  		  
			archiveArtifacts artifacts: 'report/*.md'
		}

		success {
		
			build(job: 'github-comment-label',
			  parameters:
			  [
					string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
					string(name: 'LabelCategory', value: "track-low-occ-QA"),
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
					string(name: 'LabelCategory', value: "track-low-occ-QA"),
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
					string(name: 'LabelCategory', value: "track-low-occ-QA"),
					string(name: 'LabelStatus', value: "AVAILABLE")
				],
				wait: false, propagate: false)
			slackSend (color: '#FFF000', message: "UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
	}
}//pipeline 

