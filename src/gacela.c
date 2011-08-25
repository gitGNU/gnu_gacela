/* Gacela, a GNU Guile extension for fast games development
   Copyright (C) 2009 by Javier Sancho Fernandez <jsf at jsancho dot org>

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <string.h>
#include <libguile.h>
#include <libgen.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include "gacela_SDL.h"
#include "gacela_GL.h"
#include "gacela_FTGL.h"

// Global variables
int ctrl_c = 0;
int pid = 0;
char *history_path = NULL;


static int
find_matching_paren (int k)
{
  register int i;
  register char c = 0;
  int end_parens_found = 0;

  // Choose the corresponding opening bracket
  if (k == ')') c = '(';
  else if (k == ']') c = '[';
  else if (k == '}') c = '{';

  for (i = rl_point-2; i >= 0; i--)
    {
      // Is the current character part of a character literal?
      if (i - 2 >= 0
 	  && rl_line_buffer[i - 1] == '\\'
 	  && rl_line_buffer[i - 2] == '#')
 	;
      else if (rl_line_buffer[i] == k)
 	end_parens_found++;
      else if (rl_line_buffer[i] == '"')
 	{
 	  // Skip over a string literal
 	  for (i--; i >= 0; i--)
 	    if (rl_line_buffer[i] == '"'
 		&& ! (i - 1 >= 0
 		      && rl_line_buffer[i - 1] == '\\'))
 	      break;
 	}
      else if (rl_line_buffer[i] == c)
 	{
 	  if (end_parens_found==0) return i;
 	  else --end_parens_found;
 	}
    }
  return -1;
}

static int
match_paren (int x, int k)
{
  int tmp;
  int fno;
  SELECT_TYPE readset;
  struct timeval timeout;

  rl_insert (x, k);

  // Did we just insert a quoted paren?  If so, then don't bounce
  if (rl_point - 1 >= 1
      && rl_line_buffer[rl_point - 2] == '\\')
    return 0;

  tmp = 500000;
  timeout.tv_sec = tmp / 1000000;
  timeout.tv_usec = tmp % 1000000;
  FD_ZERO (&readset);
  fno = fileno (rl_instream);
  FD_SET (fno, &readset);

  if (rl_point > 1)
    {
      tmp = rl_point;
      rl_point = find_matching_paren (k);
      if (rl_point > -1)
        {
          rl_redisplay ();
          scm_std_select (fno + 1, &readset, NULL, NULL, &timeout);
        }
      rl_point = tmp;
    }
  return 0;
}

void
ctrl_c_handler (int signum)
{
  printf ("ERROR: User interrupt\nABORT: (signal)\n");
  ctrl_c = 1;
}

void
child_dies_handler (int signum)
{
  write_history (history_path);
  exit (0);
}

static void
init_gacela_client ()
{
  struct sigaction ctrl_c_action, child_dies_action;

  // init bouncing parens
  rl_bind_key (')', match_paren);
  rl_bind_key (']', match_paren);
  rl_bind_key ('}', match_paren);

  // SIGINT
  ctrl_c_action.sa_handler = ctrl_c_handler;
  sigemptyset (&ctrl_c_action.sa_mask);
  ctrl_c_action.sa_flags = 0;

  sigaction (SIGINT, &ctrl_c_action, NULL);

  // SIGALRM
  if (pid != 0) {
    child_dies_action.sa_handler = child_dies_handler;
    sigemptyset (&child_dies_action.sa_mask);
    child_dies_action.sa_flags = 0;

    sigaction (SIGALRM, &child_dies_action, NULL);
  }

}

int
opened_parens (char *line, int k)
{
  int i;
  int opened = 0;
  char c = 0;

  // Choose the corresponding opening bracket
  if (k == ')') c = '(';
  else if (k == ']') c = '[';
  else if (k == '}') c = '{';

  for (i = 0; i < strlen (line); i++) {
    // Is the current character part of a character literal?
    if (i + 2 >= strlen (line)
	&& line[i] == '#'
	&& line[i + 1] == '\\')
      i = i + 2;
    else if (line[i] == '"') {
      // Skip over a string literal
      for (i++; i < strlen (line); i++)
	if (line[i] == '"'
	    && line[i - 1] != '\\')
 	      break;
    }
    else if (line[i] == c)
      opened++;
    else if (line[i] == k)
      opened--;
  }

  return opened;
}

void
gacela_client (SCM rec_channel, SCM send_channel)
{
  int n;
  SCM buffer;
  char *line = NULL, *line_for_sending = NULL;
  int opened = 0;

  // Command line
  asprintf (&history_path, "%s/.gacela_history", getenv("HOME"));

  init_gacela_client ();
  read_history (history_path);

  while (1) {
    if (opened > 0)
      line = readline ("... ");
    else
      line = readline ("gacela> ");

    if (!line) break;

    opened += opened_parens (line, ')');
    ctrl_c = 0;

    if (line && *line)
      {
	add_history (line);
	if (line_for_sending == NULL) {
	  line_for_sending = strdup (line);
	}
	else {
	  line_for_sending = realloc (line_for_sending, strlen (line_for_sending) + strlen (line) + 2);
	  line_for_sending = strcat (line_for_sending, " ");
	  line_for_sending = strcat (line_for_sending, line);
	}

	if (opened <= 0) {
	  scm_write (scm_from_locale_string (line_for_sending), send_channel);
	  scm_force_output (send_channel);
	  free (line_for_sending);
	  line_for_sending = NULL;

	  while (scm_char_ready_p (rec_channel) == SCM_BOOL_F) {
	    if (ctrl_c) break;
	    sleep (0.5);
	  }
	  if (ctrl_c)
	    ctrl_c = 0;
	  else {
	    buffer = scm_read (rec_channel);
	    if (strlen (scm_to_locale_string (buffer)) > 0)
	      printf ("%s\n", scm_to_locale_string (buffer));
	  }
	}
      }
    free (line);
  }

  write_history (history_path);
  free (history_path);
}

static void*
init_scheme (void *data, int argc, char **argv)
{
  // Guile configuration
  scm_c_eval_string ("(set-repl-prompt! \"gacela> \")");
  scm_c_eval_string ("(use-modules (ice-9 readline))");
  scm_c_eval_string ("(activate-readline)");
  scm_c_eval_string ("(use-modules (ice-9 optargs))");
  scm_c_eval_string ("(use-modules (ice-9 receive))");

  // Bindings for C functions and structs
  SDL_register_functions (NULL);
  GL_register_functions (NULL);
  FTGL_register_functions (NULL);

  return NULL;
}

void
load_scheme_files (char *path)
{
  char load_path[strlen (path) + 1024];

  sprintf (load_path, "(set! %%load-path (cons \"%s\" %%load-path))", path);
  scm_c_eval_string (load_path);
  scm_primitive_load_path (scm_from_locale_string ("gacela_loader.scm"));
}

void
init_gacela (char *path)
{
  scm_with_guile (&init_scheme, NULL);
  load_scheme_files (path);
  scm_c_eval_string ("(init-video-mode)");
}

void
start_server (int port)
{
  char *start_server;

  asprintf (&start_server, "(start-server #:port %d)", port);
  scm_c_eval_string (start_server);
}

void
start_local_server (SCM pipes)
{
  char start_server[100];

  scm_c_define ("pipes", pipes);
  scm_c_eval_string ("(start-server #:pipes pipes)");
}

void
start_remote_client (char *hostname, int port)
{
  SCM client_socket;
  char *connect_to_server;

  asprintf (&connect_to_server, "(let ((s (socket PF_INET SOCK_STREAM 0))) (connect s AF_INET (car (hostent:addr-list (gethost \"%s\"))) %d) s)", hostname, port);
  client_socket = scm_c_eval_string (connect_to_server);
  gacela_client (client_socket, client_socket);
}

int
main (int argc, char *argv[])
{
  char *arg;
  int mode = 0;   // dev: 1, server: 2, client: 3
  char *host;
  int port = 0;
  int i;
  SCM fd1, fd2;

  // Checking arguments
  for (i = 1; i < argc; i++) {
    if (strcmp (argv[i], "--dev") == 0)
      mode = 1;
    else if (strncmp (argv[i], "--server", 8) == 0) {
      mode = 2;
      arg = strtok (argv[i], "=");
      arg = strtok (NULL, "=");
      if (arg != NULL)
	port = atoi (arg);
    }
    else if (strncmp (argv[i], "--client", 8) == 0) {
      mode = 3;
      arg = strtok (argv[i], "=");
      arg = strtok (NULL, "=");
      if (arg != NULL) {
	host = strtok (arg, ":");
	arg = strtok (NULL, ":");
	if (arg != NULL)
	  port = atoi (arg);
      }
    }
  }

  scm_init_guile ();

  if (mode == 1) {
    fd1 = scm_pipe ();
    fd2 = scm_pipe ();
    pid = fork ();

    if (pid == 0) {
      scm_close (SCM_CAR (fd1));
      scm_close (SCM_CDR (fd2));
      init_gacela (dirname (argv[0]));
      start_local_server (scm_cons (SCM_CAR (fd2), SCM_CDR (fd1)));
      kill (getppid (), SIGALRM);
    }
    else {
      scm_close (SCM_CDR (fd1));
      scm_close (SCM_CAR (fd2));
      gacela_client (SCM_CAR (fd1), SCM_CDR (fd2));
      kill (pid, SIGKILL);
    }
  }
  else if (mode == 2 && port != 0) {
    init_gacela (dirname (argv[0]));
    start_server (port);
  }
  else if (mode == 3 && port != 0)
    start_remote_client (host, port);
  else {
    init_gacela (dirname (argv[0]));
    scm_shell (argc, argv);
    SDL_Quit ();
  }
}
