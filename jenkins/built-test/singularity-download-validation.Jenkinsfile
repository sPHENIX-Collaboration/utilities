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
							
						script {
						
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${build_type}"
							
						}
										
						dir('macros') {
							deleteDir()
						}
						dir('Singularity') {
							sh('chmod -R 755 .')
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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/opt/sphenix/core/bin/sphenix_setup.sh -n ${build_type}

env;

cd ../macros/detectors/sPHENIX/
ls -lhvc

valgrind_sup='';

if [ -f \$ROOTSYS/root.supp ]; then
	valgrind_sup="--suppressions=\$ROOTSYS/root.supp";
	echo 'use valgrind suppression file:'
	ls -lhv \$ROOTSYS/root.supp
fi	

/usr/bin/time -v  timeout --preserve-status --kill-after=1s --signal=9 1d \
	valgrind -v --num-callers=30 --gen-suppressions=all --leak-check=full \
	--error-limit=no --log-file=Fun4All_G4_sPHENIX.valgrind \$valgrind_sup \
	--xml=yes --xml-file=Fun4All_G4_sPHENIX.valgrind.xml --leak-resolution=high \
  	root.exe -b -q 'Fun4All_G4_sPHENIX.C(2)'

exit \$?
"""				
							
							sh('chmod +x test.sh')
														
							sh('ls -lvhc')
							
							sh("singularity exec -B cvmfs:/cvmfs cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.sif ./test.sh");
							
							sh('ls -lvhc')
						}

		   		}
				}// Stage download

	}//stages
		
	post {

		failure {      
        emailext (
            subject: "${currentBuild.currentResult} - Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
			to: 'pinkenbu@bnl.gov',
      		body: "Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]: ${currentBuild.currentResult}, Check console output at ${env.BUILD_URL}",
            recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
          )              
		}
		unstable {
        emailext (
            subject: "${currentBuild.currentResult} - Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
			to: 'pinkenbu@bnl.gov',
      		body: "Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]: ${currentBuild.currentResult}, Check console output at ${env.BUILD_URL}",
            recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
          )          
		}
	}
	
}//pipeline 

