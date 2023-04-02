import std.stdio;
import std.getopt;
import std.json;
import templatenest.config;

import file = std.file;

// config/command line variables
string input;

import templatenest.nest;

int main(string[] args)
{
	if (file.exists("config.json"))
	{
		// parse JSON from config.json if exists
		auto config = parseJSON(file.readText("config.json"));

		// Read a value from config.json if exists
		input.readFromConfig(config, "input");
		// TODO: add own config values
	}

	//dfmt off
	// TODO: add own command line arguments
	bool test;
	try
	{
	auto helpInformation = getopt(args,
	//	"input", "Input file to process", &input,
		"test","Test library",&test);
		
	if (test)
	{
		Nest.benchmarking();
		
	}
	else
	{
		writeln("Nothing to do.");

	}
	//dfmt on

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("Some information about the program", helpInformation.options);
		return 2;
	}

	// Program code here
	//writeln("File to process: ", input ? input : "stdin");

	return 0;
		
		
		}
	catch (GetOptException e)
	{
		writeln(e.msg);
		return 1;
	}

	
}
