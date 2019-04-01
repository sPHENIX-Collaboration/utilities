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
										
						script {
						
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${build_type}"
							
						}
										
						dir('macros') {
							deleteDir()
						}
						dir('Singularity') {
							deleteDir()
						}

						sh('hostname')
						sh('pwd')
						sh('env')
						sh('ls -lvhc')

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
						
						dir('Singularity') {
							// git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
							
							checkout(
								[
						 			$class: 'GitSCM',
						   		extensions: [               
							   		[$class: 'CleanCheckout'],     
						   		],
							  	branches: [
							    	[name: "*/master"]
							    ], 
							  	userRemoteConfigs: 
							  	[[
							    	//credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
							     	credentialsId: 'sPHENIX-bot', 
							     	url: 'https://github.com/sPHENIX-Collaboration/Singularity.git',
							     	refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
							    	branch: ('*')
							  	]]
								] //checkout
							)//checkout
						}//						dir('Singularity') {
						
						dir('macros') {
							// git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
							
							checkout(
								[
						 			$class: 'GitSCM',
						   		extensions: [               
							   		[$class: 'CleanCheckout'],     
						   		],
							  	branches: [
							    	[name: "*/master"]
							    ], 
							  	userRemoteConfigs: 
							  	[[
							    	//credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/coresoftware.git'
							     	credentialsId: 'sPHENIX-bot', 
							     	url: 'https://github.com/sPHENIX-Collaboration/macros.git',
							     	refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
							    	branch: ('*')
							  	]]
								] //checkout
							)//checkout
						}//						dir('macros') {
						
					}
				}
			}
		}//stage('SCM Checkout')
		
		// hold this until jenkins supports nested parallel
		//stage('Build')
		//{
		//	parallel {
			
				stage('download')
				{
					steps 
					{
						
						dir('Singularity') {
							sh('pwd')
							sh('ls -lvhc')
							
							sh("./updatebuild.sh -b=${build_type}");
							
							sh('ls -lvhc')
							sh('ls -lvhc cvmfs/')
							sh('du -h --max-depth=1')
						}

		   		}
				}// Stage download
				 
				
				stage('test')
				{
					steps 
					{
						
						//dir('macros/macros/g4simulations/') {
												
						dir('Singularity') {
						
							sh('pwd')
							
							writeFile file: "test.sh", text: """
#! /bin/bash

source /opt/sphenix/core/bin/sphenix_setup.sh -n ${build_type}

env;

cd ../macros/macros/g4simulations/
ls -lhvc


root -b -q Fun4All_G4_sPHENIX.C

exit \$?
							"""				
							
							sh('chmod +x test.sh')
														
							sh('ls -lvhc')
							
							sh("singularity exec -B cvmfs:/cvmfs cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.simg ./test.sh");
							
							sh('ls -lvhc')
						}

		   		}
				}// Stage download

	}//stages
		
	post {
		always{
		    
        emailext (
            subject: "always: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<html>
<body>
Hi there $DOTCI_PUSHER
<br>
<br>
You are receiving this email because Build $BUILD_NUMBER has been set to: $BUILD_STATUS
<br>
<br>
<u>Execution Results :</u><br>
Avg : ${BUILD_LOG_REGEX, regex="Avg:", showTruncatedLines=false}<br>
Min : ${BUILD_LOG_REGEX, regex="Min:", showTruncatedLines=false}<br>
Max : ${BUILD_LOG_REGEX, regex="Max:", showTruncatedLines=false}<br>
Errors : ${BUILD_LOG_REGEX, regex="Err:", showTruncatedLines=false}<br>
<br>
Build URL : $BUILD_URL
<br>
<br>
Console Output: <br>
<pre>${BUILD_LOG, maxLines=20}</pre>
</body>
</html>""",
            recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
          )
          
		}


		success {
			slackSend (color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
		failure {
        emailext (
            subject: "failure: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<html>
<body>
Hi there $DOTCI_PUSHER
<br>
<br>
You are receiving this email because Build $BUILD_NUMBER has been set to: $BUILD_STATUS
<br>
<br>
<u>Execution Results :</u><br>
Avg : ${BUILD_LOG_REGEX, regex="Avg:", showTruncatedLines=false}<br>
Min : ${BUILD_LOG_REGEX, regex="Min:", showTruncatedLines=false}<br>
Max : ${BUILD_LOG_REGEX, regex="Max:", showTruncatedLines=false}<br>
Errors : ${BUILD_LOG_REGEX, regex="Err:", showTruncatedLines=false}<br>
<br>
Build URL : $BUILD_URL
<br>
<br>
Console Output: <br>
<pre>${BUILD_LOG, maxLines=20}</pre>
</body>
</html>""",
            recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
          )
          
			slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
		unstable {
        emailext (
            subject: "unstable: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            body: """<html>
<body>
Hi there $DOTCI_PUSHER
<br>
<br>
You are receiving this email because Build $BUILD_NUMBER has been set to: $BUILD_STATUS
<br>
<br>
<u>Execution Results :</u><br>
Avg : ${BUILD_LOG_REGEX, regex="Avg:", showTruncatedLines=false}<br>
Min : ${BUILD_LOG_REGEX, regex="Min:", showTruncatedLines=false}<br>
Max : ${BUILD_LOG_REGEX, regex="Max:", showTruncatedLines=false}<br>
Errors : ${BUILD_LOG_REGEX, regex="Err:", showTruncatedLines=false}<br>
<br>
Build URL : $BUILD_URL
<br>
<br>
Console Output: <br>
<pre>${BUILD_LOG, maxLines=20}</pre>
</body>
</html>""",
            recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
          )
			slackSend (color: '#FFF000', message: "UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
		}
	}
	
}//pipeline 

