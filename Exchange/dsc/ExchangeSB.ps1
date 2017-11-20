#
# ExchangeSB.ps1
#
Configuration ExchangeSB
{
 Node "localhost"
 {
	  WindowsFeature MSMQ
        {
			 Name = "MSMQ"

            Ensure = "Present"
		}

	WindowsFeature MSMQ-services
        {
			 Name = "MSMQ-Services"

            Ensure = "Present"
		}
	 WindowsFeature MSMQ-server
        {
			 Name = "MSMQ-Server"

            Ensure = "Present"
		}

	  WindowsFeature MSMQ-Directory
        {
			 Name = "MSMQ-Directory"

            Ensure = "Present"
		}

 }
	}