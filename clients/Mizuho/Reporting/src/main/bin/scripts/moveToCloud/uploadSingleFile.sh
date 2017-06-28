cd /root/Projects/DemoRepo/clients/Mizuho/scripts/moveToCloud
perl moveToCloud.pl -source ../../data/AssetsImportCompleteSample.csv -target softlayer::dallas::csv_landing_zone::AssetsImportCompleteSample.csv -creds creds-bluemix-object-storage.txt -tmpdir temp -threads 6 -debug log.txt -token -nocompression
