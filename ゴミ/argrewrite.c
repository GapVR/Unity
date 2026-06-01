// Arguments Rewrite Passthru
// v0.3 1991/10/14 https://github.com/GapVR

#include <stdio.h>
#include <string.h>

#define CMDMAXLEN 8191 // CreateProcess 32767, cmd.exe 8191, ShellExecute/Ex 2048
#define BUFSIZE 256

int main(int argc, char *argv[])
{
	if (argc < 1)
		return 1;

	char strcmd[CMDMAXLEN];

	// executable
	strcpy(strcmd, argv[0]);
	strcat(strcmd, ".ori.exe");

	int i;
	for(i=1;i<argc;i++)
	{
		strcat(strcmd, " ");

		// rewrite rules
		if (((!strcmp(argv[i], "-f")) || (!strcmp(argv[i], "-format"))) && (i < (argc + 2)))
		{
			strcat(strcmd, "-f 3gp");
			i++;
			continue;
		}

		strcat(strcmd, argv[i]);
	}

	FILE *fp;
	char buf[BUFSIZE];

	if ((fp = popen(strcmd, "r")) == NULL)
		return 1;
	while (fgets(buf, BUFSIZE, fp) != NULL)
		printf("%s", buf);
	if (pclose(fp))
		return 1;

	return 0;
}
