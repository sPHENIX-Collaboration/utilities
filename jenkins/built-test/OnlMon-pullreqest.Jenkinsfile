pipeline 
{
	agent any
    
	environment {
		// coorindate for check runs
		checkrun_repo_commit = "${ghprbGhRepository}/${ghprbActualCommit}"
	}
       
	stages { 
	
		stage('Checkrun update') 
		{
		
			steps {
				
				echo("Building check run coordinate: ")
				echo("ghprbGhRepository = ${ghprbGhRepository}")
				echo("ghprbActualCommit = ${ghprbActualCommit}")
				echo("checkrun_repo_commit = ${checkrun_repo_commit}")
			
				build(job: 'github-commit-checkrun',
					parameters:
					[
						string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
						string(name: 'src_Job_id', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
						string(name: 'src_details_url', value: "${env.BUILD_URL}"),
						string(name: 'checkrun_status', value: "in_progress")
					],
					wait: false, propagate: false)
			} // steps
		} // stage('Checkrun update') 
		
		stage('Initialize') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
						
						dir('OnlMon') {
							deleteDir()
						}			
						dir('qa_html') {
							deleteDir()
						}			
						dir('report') {
						 	deleteDir()
						}		
						dir('install') {
						 	deleteDir()
						}		
						dir('build') {
						 	deleteDir()
						}
					
						sh('hostname')
						sh('pwd')
						sh('env')
						sh('ls -lvhc')

												
						script
						{
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${sha1}"
							
							if (params.upstream_build_description)
							{
								echo ("Override build descriiption with ${upstream_build_description}");
    						currentBuild.description = "${upstream_build_description}"
							}
						}
					}
				}
			}
		}
		
		stage('ContainerCheck') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
						
						dir('utilities/jenkins/built-test/') {
							
							sh('$singularity_exec_sphenix tcsh -f singularity-check.sh')
						
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
						
						dir('OnlMon') {
							// git credentialsId: 'sPHENIX-bot', url: 'https://github.com/sPHENIX-Collaboration/OnlMon.git'
							
							checkout(
							   [
				            $class: 'GitSCM',
				            extensions: [               
				                [$class: 'CleanCheckout'],     
				                
				                [
				                $class: 'PreBuildMerge',
				                options: [
				                    mergeRemote: 'origin',
				                    mergeTarget: 'main'
				                    ]
				                ],
				            ],
				            branches: [
				                [name: "${sha1}"]
				            ], 
				            userRemoteConfigs: 
				            [[
				                credentialsId: 'sPHENIX-bot', 
				                url: 'https://github.com/${ghprbGhRepository}.git', // https://github.com/sPHENIX-Collaboration/OnlMon.git
				                refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/main:refs/remotes/origin/main'), 
				                branch: ('*')
				            ]]
				        ] //checkout
					    )// checkout
	    
	
						}//						dir('OnlMon') {
						

					}//					ansiColor('xterm') {
					
				}//				timestamps { 
				
			}//			steps 
			
		}//stage('SCM Checkout')
		
		    stage ('Git mining') {
			steps {
				discoverGitReferenceBuild (requiredResult: hudson.model.Result.SUCCESS)
				mineRepository()
				gitDiffStat()
				}
		    }
		
		stage('build-gcc')
		{
			steps 
			{			
				writeFile file: "build.sh", text:'''#!/usr/bin/env bash
				
					install_dir=$WORKSPACE/install
					build_dir=$WORKSPACE/build
					build_log=$WORKSPACE/build/build.log
					
					echo '---------------------------------'
					echo "Env setup"
					echo '---------------------------------'
					# source /opt/sphenix/core/bin/sphenix_setup.sh -n; 
					source /cvmfs/sphenix.sdcc.bnl.gov/online/alma9.2/opt/sphenix/core/bin/sphenix_setup.sh
					env;
					
					echo install at install_dir=$install_dir
					mkdir -v $install_dir
					
					echo build at build_dir=$build_dir
					mkdir -v $build_dir
					
					echo '---------------------------------'
					echo "Build isntalling -> $build_log" | tee $build_log
					echo '---------------------------------'
					
					cd $build_dir					
					$WORKSPACE/OnlMon/autogen.sh --prefix=$install_dir 2>&1 | tee $build_log
					
					ls -lhcv
					
					make -j install 2>&1 | tee $build_log	
					status=${PIPESTATUS[0]}

					pwd
					find
					
					[ $status -eq 0 ] && echo "build successful" || exit $status
         			''';//	writeFile file: "build.sh", text:'''#!/usr/bin/env bash

				sh('chmod +x build.sh');
				sh('$singularity_exec_sphenix bash build.sh')
				
				dir('report')
				{
					sh('ls -lvhc')
				  	writeFile file: "gcc.md", text: "* `gcc` compilation: [:bar_chart:Compiler report (full)](${env.BUILD_URL}/gcc/)/[(new)](${env.BUILD_URL}/gcc/new/)"				
				} // dir('report')	
			} 
		}// 		stage('build-gcc') -> build/build.log

		
		stage('build-cppcheck')
		{
			steps 
			{			
				writeFile file: "cppcheck.sh", text:'''#!/usr/bin/env bash
				
					echo '---------------------------------'
					echo "Env setup"
					echo '---------------------------------'
					source /opt/sphenix/core/bin/sphenix_setup.sh -n; 
					env;
					echo '---------------------------------'
					echo "which cppcheck?"
					echo '---------------------------------'
					which cppcheck
					
					cppcheck -q --inline-suppr  --enable=warning --enable=performance --platform=unix64 --inconclusive --xml --xml-version=2 -j 10 --std=c++17 --suppress=unknownMacro ./OnlMon  > cppcheck-result.xml 2>&1
					status=${PIPESTATUS[0]}
					
					ls -hvl cppcheck-result.xml
					wc -l cppcheck-result.xml
					head -n 10 cppcheck-result.xml
					
					[ $status -eq 0 ] && echo "build successful" || exit $status
				
         			''';// writeFile file: "cppcheck.sh", text:'''#!/usr/bin/env bash

				sh('chmod +x cppcheck.sh');
				sh('$singularity_exec_sphenix bash cppcheck.sh')
				
				dir('report')
				{
					sh('ls -lvhc')
				  	writeFile file: "cpp-check.md", text: "* `cpp-check` [is ${currentBuild.currentResult}](${env.BUILD_URL}), [:bar_chart:`cppcheck` report (full)](${env.BUILD_URL}/cppcheck/)/[(new)](${env.BUILD_URL}/cppcheck/new/)"				
				} // dir('report')				
			}//steps 
		}// 		stage('build-gcc') -> build/build.log
		
		
		
	}//stages
		
	post {
		always{
			
	                script {			
				recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 1, tool: gcc(pattern: 'build/build.log')
        			recordIssues enabledForFailure: true, failedNewHigh: 1, failedNewNormal: 1, tool: cppCheck(pattern: 'cppcheck-result.xml')

        		} // script 
			
			
			dir('report')
			{
				sh('ls -lvhc')
						
				script
				{
					
    			echo("start report building ...");
    			sh ('pwd');
				
			def report_content = """
## Build & test report 
Report for [commit ${ghprbActualCommit}](${ghprbPullLink}/commits/${ghprbActualCommit}):"""
				
			if ("${currentBuild.currentResult}" == "FAILURE")
			{
  				report_content = """${report_content}
[![Jenkins on fire](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_fire-128p.png)](${env.BUILD_URL})"""
			}
			if ("${currentBuild.currentResult}" == "ABORT")
			{
  				report_content = """${report_content}
[![Jenkins aborted](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_snow-128p.png)](${env.BUILD_URL})"""
			}
			if ("${currentBuild.currentResult}" == "SUCCESS")
			{
  				report_content = """${report_content}
[![Jenkins passed](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_pass-128p.png)](${env.BUILD_URL})"""
			}

  			report_content = """${report_content}
[![Build Status](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) [builds and tests overall are ${currentBuild.currentResult}](${env.BUILD_URL})."""
				
			// reset of reports
				
    			def files = findFiles(glob: '*.md')
    			echo("all reports: $files");
    			// def testFileNames = files.split('\n')
    			for (def fileEntry : files) 
    			{    			
    				String file = fileEntry.path;    				
    				
    				String fileContent = readFile(file).trim();
    				
    				echo("$file  -> ${fileContent}");
    				
    				// update report summary
    				report_content = "${report_content}\n${fileContent}"		
    					
    			}    			
    			
  				report_content = """${report_content}

--------------------
_Automatically generated by [sPHENIX Jenkins continuous integration](${env.JOB_DISPLAY_URL})_
[![sPHENIX](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/sphenix-logo-white-bg-72p.png)](https://www.sphenix.bnl.gov/web/) &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; [![jenkins.io](https://raw.githubusercontent.com/sPHENIX-Collaboration/utilities/master/jenkins/material/jenkins_logo_title-72p.png)](https://jenkins.io/)"""
    			
			  	writeFile file: "summary.md", text: "${report_content}"		
			  	
    				// update build description
    				currentBuild.description = "${currentBuild.description}\n${report_content}"	
				
				build(job: 'github-comment-label',
					  parameters:
					  [
							string(name: 'ghprbPullLink', value: "${ghprbPullLink}"), 
							string(name: 'LabelCategory', value: ""),
							string(name: 'githubComment', value: "${report_content}")
						],
						wait: false, propagate: false)
			  	
				build(job: 'github-commit-checkrun',
					parameters:
					[
						string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
						string(name: 'src_Job_id', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
						string(name: 'src_details_url', value: "${env.BUILD_URL}"),
						string(name: 'checkrun_status', value: "completed"),
						string(name: 'checkrun_conclusion', value: "${currentBuild.currentResult}"),
						string(name: 'output_title', value: "sPHENIX Jenkins Report for ${env.JOB_NAME}"),
						string(name: 'output_summary', value: "[![Build Status](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) [builds and tests overall are ${currentBuild.currentResult}](${env.BUILD_URL})."),
						string(name: 'output_text', value: "${currentBuild.displayName}\n\n${currentBuild.description}")
					],
					wait: false, propagate: false
				) // build(job: 'github-commit-checkrun',
			
				}// script
				
			}
			
			archiveArtifacts artifacts: 'report/*.md'
			
			archiveArtifacts artifacts: "build/build.log"
		}
	}
	
}//pipeline 
