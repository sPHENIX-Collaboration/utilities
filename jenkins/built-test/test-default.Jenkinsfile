pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
    options {
        timeout(time: 2.5, unit: 'HOURS') 
    }
       
	stages { 
	
		stage('Prebuild-Cleanup') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
					
						script {
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${system_config} - ${build_type} - ${macro_name}"
							currentBuild.description = "${upstream_build_description} - ${system_config} - ${build_type}" 
						
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
							
							sh('rm -fv *.*')					
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
    				
						
					}
				}
			}
		}//stage('SCM Checkout')
		
		stage('Test')
		{
			
			
			steps 
			{
					
				sh("/usr/bin/singularity exec -B /cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg sh utilities/jenkins/built-test/test-default.sh ${macro_name} 30 0")
														
			}				
					
		}
		
		stage('report')
		{
			steps 
			{
			
				archiveArtifacts artifacts: 'macros/macros/g4simulations/*.root'
			
			}		
		}
		
	}//stages

	
	post {

		always{
		  
			dir('report')
			{
			  writeFile file: "test-default-${system_config}-${build_type}-${macro_name}.md", text: "* [![Build Status](https://web.racf.bnl.gov/jenkins-sphenix/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) system `${system_config}`, build `${build_type}`: run the default `${macro_name}.C` macro: [build is ${currentBuild.currentResult}](${env.BUILD_URL}), [output](${env.BUILD_URL}) "				
			}
		  		  
			archiveArtifacts artifacts: 'report/*.md'
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

