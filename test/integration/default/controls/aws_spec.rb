# encoding: utf-8
# author: Chris W. Gerber


control 'ec2-metadata-tool' do
  impact 1.0
  title 'Verify ec2-metadata'
  desc 'Verify the installation and configuration of the ec2-metadata command.'

  describe file('/usr/local/bin/ec2-metadata') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_executable.by('owner') }
    it { should be_executable.by('group') }
    it { should be_executable.by('others') }
  end
end


control 'aws-ssm' do
  impact 1.0
  title 'Verify AWS SSM'
  desc 'Ensures that AWS SSM is installed and running.'

  # EC2 Only
  only_if { os.linux? }

  describe package('amazon-ssm-agent') do
    it { should be_installed }
  end
  describe service('amazon-ssm-agent') do
    it { should be_running }
  end
end


control 'aws-xray' do
  impact 1.0
  title 'Verify AWS X-Ray'
  desc 'Ensures that AWS X-ray is installed and running.'

  # EC2 Only
  only_if { os.linux? }

  describe package('xray') do
    it { should be_installed }
  end
  describe service('xray') do
    it { should be_running }
  end
end


control 'aws-logs' do
  impact 1.0
  title 'Verify AWS Logs Agent'
  desc 'Ensures that AWS Logs Agent is installed and running.'

  # EC2 Only
  only_if { os.linux? }

  describe package('awslogs') do
    it { should be_installed }
  end

  describe sysv_service('awslogs') do
    it { should be_running }
  end
end
