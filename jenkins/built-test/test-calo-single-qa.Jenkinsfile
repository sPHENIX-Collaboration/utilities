pipeline 
{
	agent none
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
       
	stages { 
	
		stage('Prebuild-Cleanup') 
		{
			agent any
            
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
					}
				}
			}
		}
	
		stage('Initialize') 
		{
			agent any
            
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
			agent any
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
					}
				}
			}
		}//stage('SCM Checkout')
		
		stage('Test-e-')
		{
			agent any
			
			steps 
			{
					
				sh('/usr/bin/singularity exec -B /var/lib/jenkins/singularity/cvmfs:/cvmfs -B /gpfs -B /direct -B /afs -B /sphenix /var/lib/jenkins/singularity/cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg tcsh -f utilities/jenkins/built-test/test-calo-single-qa.sh e- 4 10')
														
			}				
					
		}
		
	}//stages

	
}//pipeline 

