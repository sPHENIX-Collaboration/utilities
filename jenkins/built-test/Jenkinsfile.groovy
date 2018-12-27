pipeline 
{

    agent none
    
    environment { 
//        JenkinsBase = 'jenkins/test/'
    }
    
    
        stages { 
            stage('Initialize') 
            {
        agent any
            
                steps {
                        timestamps {
	                        ansiColor('xterm') {
	                   				 echo 'Example - Entry'
                            sh('hostname')
                            sh('pwd')
	                   			 sh ('env');
                            sh('ls -lvhc')
	                   				 echo 'Example - Done'
	                        }
                        }
                }
            }
                   
            stage('SCM Checkout')
            {
        agent any
                steps 
                {
                        timestamps {
                        
	                        ansiColor('xterm') {
                        
                   				 echo 'SCM Checkout - Entry'
                        
                            dir('coresoftware') {
                                git url: 'https://github.com/sPHENIX-Test/coresoftware.git'
                            }
                            dir('coresoftware') {
                                git url: 'https://github.com/sPHENIX-Test/coresoftware.git'
                            }
                            dir('online_distribution') {
                                git url: 'https://github.com/sPHENIX-Test/online_distribution.git'
                            }

                            sh('ls -lvhc')
                            sh('pwd')
                            
                            
                   				 echo 'SCM Checkout - Done'
                        }
                        }
                }
             }
    
}
