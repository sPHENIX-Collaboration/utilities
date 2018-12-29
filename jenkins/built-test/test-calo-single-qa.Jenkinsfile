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
							if (fileExists('./build'))
							{
								sh "rm -fv ./build"
							}
							if (fileExists('./calibrations'))
							{
								sh "rm -fv ./calibrations"
							}
						
						}
						
    				
						echo("link builds to ${build_src}")
						sh('ln -svfb ${build_src}/build ./build')
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
							git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Test/macros.git', branch:'calo-single-qa'
    						}	
    				
						dir('coresoftware') {
							git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
						}
						
						dir('macros/macros/g4simulations/reference')
						{
    					copyArtifacts(projectName: "test-calo-single-qa-reference", selector: lastSuccessful());
						}
						
					}
				}
			}
		}//stage('SCM Checkout')
		
		stage('Test-e-')
		{
			
			
			steps 
			{
					
				sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-calo-single-qa.sh e- 4 15')
														
			}				
					
		}
		stage('Test-pi+')
		{
			
			
			steps 
			{
					
				sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-calo-single-qa.sh pi+ 30 15')
														
			}				
					
		}
		
	}//stages

	
	post {
		always{
			archiveArtifacts artifacts: 'macros/macros/g4simulations/G4sPHENIX_*_Sum*_qa.root*', onlyIfSuccessful: true		    
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

