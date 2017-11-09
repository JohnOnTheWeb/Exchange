Configuration FileResourceDemo
{
	Node "localhost"
	{
		File CreateFile
		{
			DestinationPath = 'c:\Test.txt'
			Ensure = "Present"
			Contents = 'Hello World!'
			}
		}
}