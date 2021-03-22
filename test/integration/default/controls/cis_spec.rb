# encoding: utf-8
# author: Chris W. Gerber

cis_attrs = attribute(
    'cis_benchmarks',
    default: {},
    description: 'CIS Benchmarks'
)

include_controls 'cis-benchmark' do
  cis_attrs['to_be_implemented'].each do |sk|
    control "cis-dil-benchmark-#{sk}" do
      describe "cis-dil-benchmark-#{sk}" do
        skip 'To be implemented'
      end
    end
  end
end

include_controls 'cis-benchmark' do
  cis_attrs['will_not_implement'].each do |sk|
    control "cis-dil-benchmark-#{sk}" do
      if sk == '1.5.2' then
        # Handle 1.5.2 in a special way because of issues with dmesg grepping.
        describe command('cat /var/log/dmesg | grep NX') do
          its(:stdout) { should match(/NX \(Execute Disable\) protection: active/) }
        end
      else
        describe "cis-dil-benchmark-#{sk}" do
          skip 'Will not implement'
        end
      end
    end
  end
end
