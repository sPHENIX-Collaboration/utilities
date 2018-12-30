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
		
		stage('html-report')
		{
			steps 
			{
			
				archiveArtifacts artifacts: 'macros/macros/g4simulations/G4sPHENIX_*_Sum*_qa.root*'
			
				script{
			    def built = build(job: 'test-calo-single-qa-gallery',
			    	parameters:
			    	[string(name: 'build_src', value: "${env.JOB_NAME}"),
			    	string(name: 'ref_build_id', value: "${env.BUILD_NUMBER}")], 
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

