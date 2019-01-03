pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
       
	stages { 
	
		stage('Prebuild-Cleanup') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
					
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
						
						dir('macros')
						{
							// git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Test/macros.git', branch:'calo-single-qa'							
							
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
							    	//credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Test/coresoftware.git'
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
					
				sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-default.sh  1 1')
														
			}				
					
		}
		
		stage('report')
		{
			steps 
			{			
				archiveArtifacts artifacts: 'macros/macros/g4simulations/*.valgrind*'
				
				publishValgrind (
          failBuildOnInvalidReports: false,
          failBuildOnMissingReports: true,
          failThresholdDefinitelyLost: '5',
          failThresholdInvalidReadWrite: '1',
          failThresholdTotal: '',
          pattern: 'macros/macros/g4simulations/*.valgrind.xml',
          publishResultsForAbortedBuilds: false,
          publishResultsForFailedBuilds: false,
          sourceSubstitutionPaths: '',
          unstableThresholdDefinitelyLost: '1',
          unstableThresholdInvalidReadWrite: '',
          unstableThresholdTotal: ''
        )
			
			}		
		}
		
	}//stages

	
	post {

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

