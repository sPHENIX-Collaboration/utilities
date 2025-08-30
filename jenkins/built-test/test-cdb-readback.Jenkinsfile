pipeline 
{
	agent any

//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
    options {
        timeout(time: 1, unit: 'HOURS') 
    }
       
	stages { 
	
	
		stage('Initialize') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
					
						sh('hostname')
						sh('pwd')
						sh('env')
						
						sh('ls -lvhc')
    				
						
					}
				}
			}
		}
 
		stage('Test CDB')
		{
			
			
			steps 
			{
					
				sh("$singularity_exec_sphenix bash utilities/jenkins/built-test/test-cdb-readback.sh")
														
			}				
					
		}

        
	}//stages

	
	post {
		always{
			archiveArtifacts artifacts: '*.log'
		}
	}
}//pipeline 

