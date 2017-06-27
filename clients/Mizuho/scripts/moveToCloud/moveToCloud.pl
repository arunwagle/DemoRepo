#!/usr/bin/perl
# Licensed Materials - Property of IBM
# moveToCloud.pl
#
# (C) Copyright IBM Corp. 2014, 2015
#
# US Government Users Restricted Rights - Use, duplication, or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# The following sample of source code ("Sample") is owned by International
# Business Machines Corporation or one of its subsidiaries ("IBM") and is
# copyrighted and licensed, not sold. You may use, copy, modify, and
# distribute the Sample in any form without payment to IBM, for the purpose of
# assisting you in the development of your applications.
#
# The Sample code is provided to you on an "AS IS" basis, without warranty of
# any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
# IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
# not allow for the exclusion or limitation of implied warranties, so the above
# limitations or exclusions may not apply to you. IBM shall not be liable for
# any damages you suffer as a result of using, copying, modifying or
# distributing the Sample, even if IBM has been advised of the possibility of
# such damages.

# Undocumented options:
# -chunk <MB_per_chunk>
# -block <MB_per_block>
# -debug <debug_file>
# -keep (do not clean up temporary files)

################################################################################
################################################################################
#
# DEFINES
#
################################################################################
################################################################################

package MoveToCloud::Constants;

use 5.010;
use strict;
use warnings;
use File::Basename;

use constant MEGABYTES          => 1024 * 1024;           # 1 MB
use constant DFT_THREADS        => 5;                     # Default number of concurrent threads
use constant DFT_BLOCK_SZ       => 16;                    # Default memory block size in MB
use constant DFT_CHUNK_SZ       => 100;                   # Default file chunk size in MB
use constant MAX_OPEN_ATTEMPTS  => 5;                     # Maximum number of attempts to open a file
use constant MAX_PUT_ATTEMPTS   => 5;                     # Maximum number of attempts to put a file
use constant MAX_TRY_ATTEMPTS   => 5;                     # Maximum number of attempts to try until success
use constant ATTEMPT_SLEEP      => 5;                     # Sleep time between attempts
use constant PROMPT_TIMEOUT     => 300;                   # Seconds before prompt times out
use constant PART_SIZE_LIMIT    => 5 * 1024 * MEGABYTES;  # Size limit for a single part

# Child exit values
use constant CHILD_ERR_NO       => 0;
use constant CHILD_ERR_GZIP     => 1;
use constant CHILD_ERR_UPLOAD   => 2;
use constant CHILD_ERR_INT      => 3;

package MoveToCloud;
use File::Basename;

our $STARTTIME = localtime();
our $scriptID  = time().$$;

our $DEBUG           = 0;  # debug flag
our $VERBOSE         = 0;  # verbose flag
our $QUIET           = 0;  # quiet flag
our $keepFile        = 0;  # keep temporary files?
our $verboseToStdout = 0;  # print vebose to stdout?
our $compress        = 1;  # compress file?
our $target          = ""; # reference to target object
our $errorexit       = -1; # 1 = on, 0 = off, -1 = prompt
our $softlayer       = 0;  # is the service SoftLayer?
our $s3              = 0;  # is the service S3?
our $mode            = ""; # single/batch/list/delete
our %filehandles     = (); # open filehandles list hash
our $isChild         = 0;  # are we a child?
our $maxThreads      = MoveToCloud::Constants::DFT_THREADS;
our $blockSize       = MoveToCloud::Constants::DFT_BLOCK_SZ * MoveToCloud::Constants::MEGABYTES;
our $chunkSize       = MoveToCloud::Constants::DFT_CHUNK_SZ * MoveToCloud::Constants::MEGABYTES;
our $curlStmt        = 0;  # curl statement number

our  %services = ( 'softlayer'       => "IBM SoftLayer Object Storage",
                   's3'              => "Amazon AWS Simple Storage Service" );

our %s3_urls   = ( 'us-east-1'        => "https://s3.amazonaws.com",
                   'us-west-2'        => "https://s3-us-west-2.amazonaws.com",
                   'us-west-1'        => "https://s3-us-west-1.amazonaws.com",
                   'eu-west-1'        => "https://s3-eu-west-1.amazonaws.com",
                   'ap-southeast-1'   => "https://s3-ap-southeast-1.amazonaws.com",
                   'ap-southeast-2'   => "https://s3-ap-southeast-2.amazonaws.com",
                   'ap-northeast-1'   => "https://s3-ap-northeast-1.amazonaws.com",
                   'sa-east-1'        => "https://s3-sa-east-1.amazonaws.com" );

our %softlayer_urls = ( 'dallas'    => "https://dal.objectstorage.open.softlayer.com/v1/AUTH_9f2108032c4e44119f41ba96e9d83883",
                        'sanjose'   => "https://sjc01.objectstorage.softlayer.net/auth/v1.0/",
                        'toronto'   => "https://tor01.objectstorage.softlayer.net/auth/v1.0/",
                        'amsterdam' => "https://ams01.objectstorage.softlayer.net/auth/v1.0/",
                        'london'    => "https://lon02.objectstorage.softlayer.net/auth/v1.0/",
                        'singapore' => "https://sng01.objectstorage.softlayer.net/auth/v1.0/",
                        'hongkong'  => "https://hkg02.objectstorage.softlayer.net/auth/v1.0/" );

our $mask             = "***MASKED***";

our $scriptName       = basename($0);

our $util = MoveToCloud::Util->new;  # call methods of Util class

package MoveToCloud::Util;

use 5.010;
use strict;
use warnings;
use Carp;
use Data::Dumper;

sub new
{
  my $class = shift;
  my $self = {};
  return bless $self, $class; 
}

sub setInputs
{
  my $self = shift;
  $self->{'inputs'} = shift;
}

sub sigtrap
{
  # Signal handler function to call cleanup
  my $sigMsg = $!;

  # Make sure that if quitting while entering a password/token,
  # re-enable the character echoing 
  system('stty','echo');

  $util->printWarn( "Caught signal: $sigMsg" );

  if( $isChild )
  {
    exit MoveToCloud::Constants::CHILD_ERR_INT;
  }

  $util->cleanup();
  exit 2;
}

sub httpCodeCheck
{
  # Check the HTTP response status-code for the given value(s).
  # Given an array of response lines, searches for the last response header and
  # checks the status code value.
  # Also return the status line message.

  # Value string allows only numbers and the characters ',' and '-'
  # Value string could be a list separated by ',' and/or range indicated with a '-'
  # Returns the status code if the value was found.
  # Example value string: "100,200-299,302" returns true for all those codes only.
  my $self  = shift;
  my $value = shift;
  my @lines = @_;
  # Validate the input value string
  my @values;
  if( not($value =~ m/^(\d|,|-)+$/) )
  {
    croak( "httpStatusCheck value string \"$value\" contains invalid characters" );
  }
  @values = split( /,+/, $value );
  for( my $i = 0; $i <= $#values; $i++ )
  {
    if( $values[$i] =~ m/^(\d+)$/ )
    {
      # Just a number
      next;
    }
    if( $values[$i] =~ m/^(\d+)-(\d+)$/ )
    {
      # A range: remove from the array, push the range of values onto the end
      # of the array.
      my $m = $1;
      my $n = $2;
      my $y = splice( @values,$i,1 );
      die "BAD $y" if( !($m < $n) );
      push( @values, ($m..$n) );
      $i--; # move the counter back one, as all members were shifted left one
    }
    else
    {
      # Bad value
      croak( "httpStatusCheck value \"$values[$i]\" invalid" );
    }
  }

  # From W3 protocol docs, the first line of the response will look like:
  # HTTP-Version SP Status-Code SP Reason-Phrase CRLF

  # Use grep to get all the HTTP status lines
  my @matches;
  # Regex: begin string, non-whitespace stuff, space, 3 numeric digits (set to $1), space
  if( not( @matches = grep( /^HTTP\/1\.1 \d\d\d /, @lines) ) )
  {
    croak( "httpStatusCheck match failed" );
  }
  # Get the code from the LAST status line
  $matches[$#matches] =~ /^HTTP\/1\.1 (\d\d\d) (.+)$/;
  my $statuscode = $1;
  my $statusMsg = $2;
  chomp $statusMsg;

  # Now search the values array for the statuscode
  foreach my $code (@values)
  {
    if( $code == $statuscode )
    {
      return( $statuscode, $statusMsg );
    }
  }

  # Code does not match
  return( 0, $statusMsg );
}

sub checkContainer
{
  # Check the container name value
  my $self      = shift;
  my $container = shift;

  if( not defined $container )
  {
    croak "container name not defined, can't check";
  }

  if( $container eq "" )
  {
    $self->userError( "Must provide a non-empty container name." );
  }
  elsif( $container =~ m/\// )
  {
    $self->userError( "Container name cannot have '/' characters." );
  }
}

sub cleanup
{
  # Do cleanup before exiting
  # This includes:
  # - close all filehandles
  # - kill
  my $self   = shift;
  my $inputs = $self->{'inputs'};
  if (not defined $inputs)
  {
    croak "cleanup missing inputs";
  }
  $self->printDebug( "cleanup called at line " . (caller)[2] );

  # Delete the cURL output file unless debugging
  if( !$keepFile )
  {
    if( defined $inputs->{'curlout'} )
    {
      for( my $i = 1; $i <= $curlStmt; $i++ )
      {
        if ( -f $inputs->{'curlout'}.$i )
        {
          unlink $inputs->{'curlout'}.$i or warn "Could not unlink $inputs->{'curlout'}.$i!";
        }
      }
      if ( -f $inputs->{'curlout'} )
      {
        unlink $inputs->{'curlout'} or warn "Could not unlink $inputs->{'curlout'}: $!";
      }
    }

    if( defined $inputs->{'tmpdir'} )
    {
      rmdir $inputs->{'tmpdir'}; 
    }
  }

  # Close all filehandles
  foreach my $fh (keys %filehandles)
  {
    # Don't close debug or verbose until everything else is done
    next if( $fh eq "debug" or $fh eq "verbose" );
    $self->closeFile( $fh );
  }

  # Now close verbose then debug
  if( $VERBOSE )
  {
    my $ENDTIME = localtime();
    $self->printVerbose( "End time: $ENDTIME" );
    $self->closeFile( 'verbose' ) if( not $verboseToStdout );
  }
  if( $DEBUG )
  {
    $self->printDebug( "done cleaning up, closing debug filehandle" );
    $self->closeFile( 'debug' );
  }
}

################################################################################
################################################################################
#
# Subroutines for printing messages to stdout, debug and verbose files, and
# prompting the user for input
#
################################################################################
################################################################################

sub printDebug
{
  # Print message to debug if DEBUG is on
  my $self       = shift;
  my $msg        = shift;
  my $lineNumber = shift; # Optional, used if print is cascaded from printDebug

  $lineNumber = (caller)[2] if( not defined $lineNumber );

  if( $DEBUG )
  {
    print {$filehandles{"debug"}} "$lineNumber: $msg\n";
  }
}

sub printVerbose
{
  # Print message to verbose if VERBOSE is on
  my $self       = shift;
  my $msg        = shift;
  my $lineNumber = shift || (caller)[2];
  if( $VERBOSE )
  {
    print {$filehandles{"verbose"}} "$msg\n";
  }
  # Also try printing the message to debug
  $self->printDebug( $msg, $lineNumber );
}

sub printWarn
{
  # Print message to standard err (if QUIET is not on)
  my $self = shift;
  my $msg  = shift;

  my $lineNumber = (caller)[2];
  $self->printVerbose( $msg, $lineNumber );

  if( not $verboseToStdout )
  {
    if( not $QUIET )
    {
      print STDERR "$msg\n";
    }
  }
}

sub printOut
{
  # Print message to standard out (if QUIET is not on)
  my $self = shift;
  my $msg  = shift;

  my $lineNumber = (caller)[2];
  $self->printVerbose( $msg, $lineNumber );
  if( not $verboseToStdout )
  {
    if( not $QUIET )
    {
      print STDOUT "$msg\n";
    }
  }
}

sub userError
{
  # User input error
  # Print message to stdout and exit with rc =  1 (user error)
  my $self     = shift;
  my $errorStr = shift;

  $self->printVerbose( "ERROR: " . $errorStr );

  croak "errorStr empty" if( not defined $errorStr );
  
  $self->printOut( "Input error. Message:\n$errorStr" );

  $self->cleanup();

  exit 1;
}

sub promptUser
{
  # Print text and get response
  my $self    = shift;
  my $message = shift;
  my $secret  = shift;
  my $response;

  my $hideInput = 0;

  if( $secret )
  {
    $hideInput = 1;
  }

  # Print the message
  $self->printOut( $message );

  # Get a response
  # We set a time limit and if no response is received just return the default
  my $timedout = 0;
  eval
  {
    # Set the alarm signal handler to:
    #   switch $timedout to true
    #   exit this eval block (via die)
    local $SIG{ALRM} = sub { $timedout = 1; die };
    # Start the clock
    alarm MoveToCloud::Constants::PROMPT_TIMEOUT;
    # Try reading the response
    if( $hideInput )
    {
      system('stty','-echo');
      $response = <STDIN>;
      system('stty','echo');
    }
    else
    {
      $response = <STDIN>;
    }
    # Turn off the alarm
    alarm 0;
  };
  if( $timedout )
  {
    return;
  }
  else
  {
    chomp  $response;
    return $response;
  }
}

sub askUser
{
  # Ask the user a question with limited answers
  my $self     = shift;
  my $question = shift;
  my $inputs   = shift;
  my @options  = @_;

  if( not defined $options[0] ||
      $options[0] eq "" )
  {
    croak "askUser needs options";
  }

  # Set the default to the first option
  my $default = $options[0];

  # Add "quit" as an option
  push( @options, "quit" );

  if( $QUIET )
  {
    # If QUIET do not prompt, instead return the default
    $self->printVerbose( "Quiet mode. Did not prompt \"$question\". Used default \"$options[0]\"." );
    return $default;
  }
  else
  {
    # Format the question by showing the valid responses
    my $list = join('|',@options);
    $question = "$question [$list]: ";

    # Now prompt the user until they give a valid response
    while(1)
    {
      my $response = $self->promptUser( $question );

      if( not defined $response )
      {
        # Warn the user and return the default
        $self->printWarn( "Prompt timed out. Using default value \"$default\"." );
        return $default;
      }

      if( grep(/^\Q$response\E$/,@options) )
      {
        # Valid response
        if( $response eq 'quit' )
        {
          $self->printOut( "Exiting..." );
          $self->cleanup();
          exit 1;
        }
        else
        {
          return $response;
        }
      }
      else
      {
        $self->printDebug( "invalid response" );
      }
    }
  }
}

sub askBool
{
  # Ask a yes or no question.
  # Default to the negative (in case of timeout / -quiet mode).
  # User options -yes and -no can automatically answer these.
  my $self       = shift;
  my $question   = shift;
  my $inputs_ref = shift;

  # Check the command line options
  if ( defined $inputs_ref->{'yes'} )
  {
    return $inputs_ref->{'yes'};
  }

  # Else we need to ask the question
  my $answer = $self->askUser( $question, $inputs_ref, 'no', 'yes' );

  return 1 if( $answer eq 'yes' );

  return 0;
}

################################################################################
################################################################################
#
# Subroutines for file and directory operations 
#
################################################################################
################################################################################

sub checkReadFile
{
  # Check that the input file is valid
  my $self = shift;
  my $tag  = shift;
  my $file = shift;

  croak "checkReadFile missing input" if( $file eq "" or $tag eq "" );

  # File must be readable and be a file
  if( not (-r $file && -f _) )
  {
    $self->userError( "$tag file \"$file\" does not exist or is not readable. Check path and permissions." );
  }
  
  # File must be at least 1 byte in size
  if ((-s "$file")<1) 
  {
      $self->userError( "$tag file \"$file\" has 0 bytes in size and won't be processed. Remove the file from the list." );
  }
  
}

sub checkWriteDir
{
  # Check that the directory path is writeable (create it if necessary)
  my $self = shift;
  my $tag  = shift;
  my $dir  = shift;

  croak "checkWriteDir missing input" if( $dir eq "" or $tag eq "" );

  if( -d $dir )
  {
    # Directory exists
    if( not (-r $dir && -w _) )
    {
      # But we don't have the correct permissions
      $self->userError( "$tag directory \"$dir\" does not have the required permissions. Allow read and write access." );
    }
    # All is well, nothing more to do
  }
  else
  {
    # Directory does not exist so create it
    mkdir( $dir, 0700 )
      or $self->userError( "Cannot create $tag directory at \"$dir\". Error: \"$!\"." );
  }
}

sub openFile
{
  # Open a file and store the file handle
  # On error, cleanup and exit
  my $self     = shift;
  my $tag      = shift;
  my $openMode = shift;
  my $file     = shift;
  my $errexit  = shift; # Exit on error. Default 1 (yes)
  my $message  = shift;

  croak "openFile missing input" if( not defined $file );

  if( not defined $errexit )
  {
    $errexit = 1;
  }

  if( $openMode ne '<' and
      $openMode ne '>' )
  {
    croak "openFile mode '$openMode' invalid";
  }

  my $attempts = 0;
  my $errorMsg = "";
  my $rc = open( $filehandles{$tag}, $openMode, $file );
  while( not $rc )
  {
    $errorMsg = $!;
    $attempts++;
    last if( $attempts >= MoveToCloud::Constants::MAX_OPEN_ATTEMPTS );
  }
  continue
  {
    sleep MoveToCloud::Constants::ATTEMPT_SLEEP;
    $rc = open( $filehandles{$tag}, $openMode, $file );
  }

  if( not $rc )
  {
    # Failed to open file after max attempts
    $errorMsg =  "Failed to open $tag file $file: $errorMsg";
    if( $errexit )
    {
      $self->userError( $errorMsg );
    }
    else
    {
      return $errorMsg;
    }
  }

  if( defined $message )
  {
    print {$filehandles{$tag}} $message;
  }

  # Success
  $self->printDebug( "opened $file as $tag successfully after $attempts attempts" );
  return;
}

sub closeFile
{
  # Close the given file tag in the %filehandles hash
  my $self = shift;
  my $tag  = shift || croak "closeFile missing input";

  $self->printDebug( "closing $tag" );

  if( $filehandles{$tag} )
  {
    # Delete key from hash and close that key's value (the FH)
    close( delete($filehandles{$tag}) );
  }
  else
  {
    $self->printDebug( "$tag already closed" );
  }
}

sub getLine
{
  # Get a line of text from a file
  # Skip any blank or comment lines
  my $self = shift;
  my $tag  = shift;
  my $fh;

  croak "getLine missing input" if( not defined $tag );
  if( not defined($filehandles{$tag}) )
  {
    croak "getLine filehandle \"$tag\" invalid";
  }
  else
  {
    $fh = $filehandles{$tag};
  }

  my $skippedLines = 0;
  my $line;
  my $lineNumber = -1; # -1 indicates no line returned

  while( $line = <$fh> )
  {
    chomp $line;
    $line =~ s/^\s*//; # trim any leading whitespace
    $line =~ s/\s*$//; # trim any trailing whitespace
    if( $line eq "" or      # blank line
        $line =~ m/^\s*#/ ) # comment line
    {
      $skippedLines++;
      next;
    }
    else
    {
      $lineNumber = $.;
      last;
    }
  }

  $self->printDebug( "got line $lineNumber, skipped $skippedLines, from tag $tag" );
  return $line, $lineNumber;
}

sub retry
{
  # Check for output until successful or attempts are done
  my $self        = shift;
  my $subroutine  = shift;
  my @params      = @_;
  my $attempt     = 0;
  my $returnVal; 
  
  while ( $attempt < MoveToCloud::Constants::MAX_TRY_ATTEMPTS )
  {
    return $returnVal  if eval { $returnVal = $subroutine->(@params) };   
    if ( not $returnVal )
    {
      $attempt++;
      sleep MoveToCloud::Constants::ATTEMPT_SLEEP;
      next;
    }
  }
  croak qq(Failed after $attempt attempts. Undefined value: $@);
}

package MoveToCloud::BatchUpload;

use Carp;
use File::Basename;
use Data::Dumper;

sub new
{
  my $class                 = shift;
  my $self                  = {};
  $self->{'source'}{'name'} = shift;
  $self->{'target'}         = shift;
  bless $self, $class;
  return $self;
}

sub setSource
{
  my $self = shift;
  $self->{'source'}{'name'} = shift;
}

sub getSource
{
  my $self = shift;
  return $self->{'source'}{'name'};
}

sub setTarget
{
  my $self = shift;
  $self->{'target'} = shift;
}

sub getTarget
{
  my $self = shift;
  return $self->{'target'};
}

sub setSkip
{
  my $self = shift;
  $self->{'skip'} = shift;
}

sub getSkip
{
  my $self = shift;
  return $self->{'skip'};
}

sub setId
{
  my $self = shift;
  $self->{'id'} = shift;
}

sub getId
{
  my $self = shift;
  return $self->{'id'};
}

sub setSourcebasename
{
  my $self = shift;
  $self->{'source'}{'basename'} = shift;
}

sub getSourcebasename
{
  my $self = shift;
  return $self->{'source'}{'basename'};
}

sub setTargetdir
{
  my $self = shift;
  $self->{'targetdir'} = shift;
}

sub getTargetdir
{
  my $self = shift;
  return $self->{'targetdir'};
}

sub useThisUpload
{
  # Modify the %target hash for the given batch upload

  my $self       = shift;
  my $target_ref = shift;
  my $source_ref = shift;

  if( not defined $self->getSource or
      not defined $self->getTarget )
  {
    croak "useThisUpload given bad upload ref";
  }

  $source_ref->{'source'}{'name'} = $self->getSource;
  $target_ref->{'name'} = $self->getTarget;

  if( not defined $self->getSourcebasename )
  {
    croak "useThisUpload given upload ref with no sourcebasename";
  }
  $source_ref->{'source'}{'basename'} = $self->getSourcebasename;

  if( not defined $self->getTargetdir )
  {
    croak "useThisUpload given upload ref with no targetdir";
  }
  $target_ref->{'dir'} = $self->getTargetdir;

  if( $softlayer )
  {
    $target_ref->{'parts_dir'} = $target_ref->{'name'}.".parts/";
    $target_ref->{'parts_prefix'} = ($target_ref->{'parts_dir'}).(basename($target_ref->{'name'})).'_';
  }
}

sub checkEachUpload
{
  my $self       = shift;
  my $inputs_ref = shift;
  my $source     = $self->getSource;
  my $target     = $self->getTarget;

  if( $compress and
      $inputs_ref->isSourceCompressed($source) )
  {
    my $errorMsg = "Compression not disabled but batch upload source $source already compressed. Use the 'nocompression' batch option to disable compression.";
    $self->batchSkipPromptAndHandleResponse( $errorMsg, $inputs_ref );
  }

  my $sourcebasename = basename($source);
  # If a sourcedir is defined AND
  # if the source name is not an absolute path ...
  if( (defined $inputs_ref->{'sourcedir'}) and
      (not($source =~ m/^\//)) )
  {
    # Append the sourcedir to the source name
    $source = $inputs_ref->{'sourcedir'}.'/'.$source;
  }

  # clean up the string, removing redundant '/'
  $source =~ s/\/+/\//g;
  $util->checkReadFile( "source_".$self->getId, $source );

  $util->printDebug( "source" . $self->getId . "\"$source\", basename \"$sourcebasename\"" );

  # Process the target's name

  if( $target eq "" )
  {
    # No target specified, use targetdir/
    if( not defined $inputs_ref->{'targetdir'} )
    {
      my $errorMsg = "No valid target name/path to use. Use the 'targetdir' batch option to allow empty target values.";
      $self->batchSkipPromptAndHandleResponse( $errorMsg, $inputs_ref );
      # User chose to skip
      $self->setSkip(1);
      next;
    }
    else
    {
      $target = $inputs_ref->{'targetdir'}.'/'.$sourcebasename;
    }
  }
  elsif( (not( $target =~ m/^\// )) and
         (defined $inputs_ref->{'targetdir'}) )
  {
    # The target value did not start with '/', so not an absolute path,
    # and a targetdir was given
    $target = $inputs_ref->{'targetdir'}.'/'.$target;
  }
  # Clean up the path string
  # Remove redundant '/'s, remove the leading '/'
  $target =~ s/\/+/\//g;
  $target =~ s/^\///;

  if( $target =~ m/\/$/ )
  {
    # Target name ends with a '/', so it is just a directory,
    # so use the source basename
    $target = $target.$sourcebasename;
  }

  my $targetdir = (dirname($target)).'/';
  if( $targetdir eq './' )
  {
    $targetdir = "";
  }

  if( $compress )
  {
    # Uploaded file will be compressed with gzip
    if( not($target =~ m/\.g(z|zip)$/) )
    {
      # Add .gz if the target input doesn't already use it
      $target = "$target.gz";
    }
  }

  $util->printDebug( "target" . $self->getId ."\"$target\"" );

  $self->setSource($source);
  $self->setSourcebasename($sourcebasename);
  $self->setTarget($target);
  $self->setTargetdir($targetdir);
}

sub batchSkipPromptAndHandleResponse
{
  # Given an error message and the state of flag $errorexit,
  # determine if upload should be skipped or if script should exit.
  my $self     = shift;
  my $errorMsg = shift;
  my $inputs   = shift;

  if( $errorexit == -1 )
  {
    # errorexit option not set, prompt user
    if( not $util->askBool( $errorMsg . "\nSkip this upload?", $inputs) )
    {
      $util->userError( "Skip disabled. Exiting." );
    }
  }
  if( $errorexit == 1 )
  {
    # errorexit set or user chose exit, so exit
    $util->userError( $errorMsg );
  }
  # Else just skip
  else
  {
    $self->setSkip(1);
    $util->printWarn( "Skipping upload #" . $self->getId() );
  }
}

package MoveToCloud::Curl;

use 5.010;
use strict;
use warnings;
use Carp;
use Data::Dumper;

sub new
{
  my $class = shift;

  my $self = { 'curlout'          => shift,
               'username'         => shift,
               'password'         => shift,
               'token'            => shift,
               'credentials'      => shift 
             };
  bless $self, $class;
  return $self;
}

sub setCurlout
{
  my $self = shift;
  $self->{'curlout'} = shift;
}

sub curl
{
  # Call cURL
  # Returns the response as an array of lines

  my $self    = shift;
  my $url     = shift;
  my @options = @_;
  if( not defined($options[0] ) )
  {
    croak "no options for curl";
  }

  $curlStmt++;

  my $request = "";
  foreach my $option (@options)
  {
    $request .= "$option \\\n";
  }
  $request .= "\"$url\"";
  $util->printDebug( "cURL-$curlStmt: $request" );
  my $tryResponse = sub 
  {
     # -s = silent/quiet mode
     # -S = show error
     my $response = `curl --trace-ascii $self->{'curlout'}$curlStmt -sS $request 2>>$self->{'curlout'}`;
     my $rc = $?;
     if( $rc == -1 )
     {
       if ( defined $response )
       {
         $util->printWarn("curl system call failed with output:\n\"$response\"");
       }
       else
       {
         $util->printWarn("curl system call failed");
       }
       croak "curl system call failed";
     }
     else
     {
       $rc = $rc >> 8;
       if ( $rc != 0)
       {
         $util->printWarn("curl request failed with error code: $rc");
         croak "curl request failed with error code: $rc";
       }
     }
     return $response;
  };
  my $response = $util->retry( $tryResponse );
  $response =~ s/\r\n/\n/g;
  $response =~ s/\n+/\n/g;
  # Return the separate lines as an array
  my @lines = split(/\n+/, $response);

  if( $DEBUG )
  {
    # Print the request and response to debug file
    my $debugMsg;

    $util->printDebug( "curl request (".(caller)[2]."):" );
    $debugMsg = "curl -s ";

    foreach my $option (@options)
    {
      # Mask out the authentication values
      my $username = quotemeta($self->{'username'}) if ( defined $self->{'username'});
      my $password = quotemeta($self->{'password'}) if ( defined $self->{'password'});
      my $token    = quotemeta($target->{'token'})  if ( defined $target->{'token'} );
      $option =~ s/($username|$password)/$mask/g    if ( defined $username && $password );
      $option =~ s/$token/$mask/g if( defined $token );
      $debugMsg .= "$option ";
    }
    $debugMsg .= $url;
    $util->printDebug( $debugMsg );
    $debugMsg = "curl response summary (".(caller)[2]."):\n";
    foreach my $line (@lines)
    {
      # We should only print some values, not all are necessary and some
      # contain secrets
      if( ($line =~ m/^\S+ (\d+) /) or # standard first line, contains code and message
          ($line =~ m/^(Content-Length|Date):/) or
          ($line =~ m/^X-(Timestamp|Storage-Url|Trans-Id):/ ) )
      {
        $debugMsg .= "$line\n";
      }
      elsif( $line =~ m/^X-Auth-Token:/ )
      {
        $debugMsg .= "X-Auth-Token: $line\n";
      }
    }
    chomp $debugMsg;
    $util->printDebug( $debugMsg );
  }
  return @lines;
}

package MoveToCloud::Inputs;
use 5.010;
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Cwd; 
use Carp;
use File::Basename;
use FindBin;
use Data::Dumper;


my %validBatchFileOptions = ( 'credentials'   => "",
                              'sourcedir'     => "",
                              'targetdir'     => "", 
                              'service'       => "", 
                              'url'           => "",
                              'container'     => "",
                              'threads'       => "",
                              'tmpdir'        => "",
                              'nocompression' => "",
                              'chunk'         => "",
                              'block'         => "",
                              'errorexit'     => "",
                              'usetoken'      => ""); 

my $batchOptionsStart = "==OPTIONS_START==";
my $batchOptionsEnd   = "==OPTIONS_END==";
my $batchUploadsStart = "==UPLOADS_START==";
my $batchUploadsEnd   = "==UPLOADS_END==";

sub new
{
  my $class = shift;
  my $self  = { 'source'     => undef, # holds reference to hash with source name and source basename
                'tgtService' => ""
              };
  bless $self, $class;
  return $self;
}

sub listMode
{
  # Prints out %services, %softlayer_urls, and %s3_urls

  print "$scriptName list of supported services and built in endpoints\n\n";

  # Print %services (reverse alphabetical order)
  print "Supported services:\n";
  foreach my $serviceName (sort {$b cmp $a} keys %services)
  {
    printf( "    %-16s ->   %s\n", $serviceName, $services{$serviceName} );
  }
  print "\n";

  # Print %softlayer_urls
  print "SoftLayer endpoints:\n";
  foreach my $softlayer_endpoint (sort keys %softlayer_urls)
  {
    printf( "    %-16s ->   %s\n", $softlayer_endpoint, $softlayer_urls{$softlayer_endpoint} );
  }
  print "\n";

  # Print %s3_urls
  print "S3 endpoints:\n";
  foreach my $s3_endpoint (sort keys %s3_urls)
  {
    printf( "    %-16s ->   %s\n", $s3_endpoint, $s3_urls{$s3_endpoint} );
  }

  exit 0;
}

sub parseInputs
{ 
  # Parse the user input arguments
  my $self = shift;
  my $errorStr;

  # Get the command line options (non-options will be left in ARGV)
  # Documented options are source,target,batch,test,list,help,man,creds,threads,nocompression,tmpdir,verbose,quiet,token
  # Undocumented options are chunk,block,debug,keep

  # Subroutines for setting up options
  my $setSource = sub 
  {
    my ( $option, $source ) = @_;
    if ( defined $source )
    {
      $self->setMode('s');
      $util->checkReadFile( "source", $source );
      $self->{'source'}{'name'} = $source;
    }
  };

  my $setBatch = sub 
  {
    my ( $option, $batch ) = @_;
    if( defined $batch )
    {
      $self->setMode('b');
      $util->checkReadFile("batch", $batch );
      $self->{'batch'} = $batch;
    }
  };

  my $setCreds = sub 
  {
    my ( $option, $creds ) = @_;
    if ( defined $creds )
    {
      $util->checkReadFile( "credentials", $creds );
      $self->{'credentials'} = $creds;
    }
  };

  my $setTmpDir = sub 
  {
    my ( $option, $tmpdir ) = @_;
    if ( defined $tmpdir )
    {
      $util->checkWriteDir( "tmpdir", $tmpdir );
      $self->{'tmpdir'} = $tmpdir;
    }
  };

  my $setDebug = sub 
  {
    my ( $option, $debugFile ) = @_;
    if( defined $debugFile )
    {
      $DEBUG = 1;
      my $topMessage = "$scriptName debug file\n";
      $topMessage .= '-' x 80 . "\n";
      $util->openFile( "debug", '>', $debugFile, 1, $topMessage );
    }
  };

  my $help;
  my $man;
  my $verboseFile;
  
  Getopt::Long::Configure( "long_prefix_pattern=(--|-)" );
  GetOptions( "source=s"      => $setSource,
              "target=s"      => \$self->{'target'}, 
              "batch=s"       => $setBatch,
              "test"          => sub { $self->setMode('t') },
              "delete"        => sub { $self->setMode('d'); $compress = 0 },
              "list"          => \&listMode,
              "help"          => \$help,
              "man"           => \$man,
              "creds=s"       => $setCreds,
              "threads=i"     => \$self->{'threads'},
              "nocompression" => sub { $compress = 0 },
              "token"         => \$self->{'usetoken'},
              "tmpdir=s"      => $setTmpDir,
              "verbose:s"     => \$verboseFile,
              "quiet"         => \$QUIET,
              "yes"           => \$self->{'yes'},
              "no"            => sub { $self->{'yes'} = 0 },
              "chunk=i"       => \$self->{'chunk'},
              "block=i"       => \$self->{'block'},
              "debug=s"       => $setDebug, 
              "keep"          => \$keepFile
            ) or pod2usage({ -exitval => 0 });

  # -help triggers brief help
  pod2usage( -exitval => 0,
             -verbose => 1 ) if defined $help;
  # -man triggers manual
  pod2usage( -exitval => 0,
             -verbose => 2 ) if defined $man;

  if( $mode eq "" )
  {
    $util->userError( "No mode specified." );
  }

  # Finish setting up verbose mode if specified
  if( defined $verboseFile )
  {
    $VERBOSE = 1;
    # File name is optional, if not provided then use STDOUT
    if( $verboseFile eq "" )
    {
      $filehandles{'verbose'} = *STDOUT;
      $verboseToStdout = 1;
      if ( $QUIET )
      {
        $util->userError( "Cannot be QUIET and VERBOSE to STDOUT at the same time." );
      }
    }
    else
    {
      my $topMessage = "$scriptName message file\n";
      $topMessage .= '-' x 80 . "\n";
      $util->openFile( "verbose", '>', $verboseFile, 1, $topMessage );
    }
  }

  $util->printVerbose( "Start time: $STARTTIME" );
  $util->printVerbose( "Process ID: $$" );
  $util->printVerbose( "Run mode: $mode" );

  # Finish verifying target option
  if( defined $self->{'target'} )
  {
     $self->{'target'}  =~ /^(.+?)::/;
     if ( not defined $1)
     {
        $util->userError( "Target in wrong format.");
     }
     elsif ( lc($1) eq 's3' )
     {
        $self->{'tgtService'} = "s3";
        if ( $self->{'usetoken'} )
        {
           $util->userError( "-token argument is incompatible with s3." );
        }
     }

     if( $mode eq "batch" )
     {
        $util->userError( "-target argument is incompatible with -batch." );
     }
  }
  elsif( $mode ne 'batch' )
  {
     # All but batch require -target
     $util->userError( "Mode $mode requires -target argument." );
  }

  if( $compress == 0 )
  {
    $util->printVerbose( "Compression disabled." ) if ($mode ne 'delete');
  } 

  # Parse the batch file
  if( $mode eq "batch" )
  {
    $util->printVerbose( "Batch file: " . $self->{'batch'} );
    $self->parseBatch();
  }

  $self->getCredentials();

  if( defined $self->{'threads'} )
  {
    $maxThreads = $self->{'threads'};
  }
  if( defined $self->{'chunk'} )
  {
    $chunkSize  = $self->{'chunk'} * MoveToCloud::Constants::MEGABYTES;
  }
  if( defined $self->{'block'} )
  {
    $blockSize  = $self->{'block'} * MoveToCloud::Constants::MEGABYTES;
  }

  if( $chunkSize > MoveToCloud::Constants::PART_SIZE_LIMIT or
      $blockSize > MoveToCloud::Constants::PART_SIZE_LIMIT )
  {
    $util->userError( "Part size limit is 5GB. Chunk and block sizes cannot exceed this limit." );
  }
  if( $blockSize > $chunkSize )
  {
    $util->userError( "Block size cannot be greater than chunk size.\n" .
                      "Check command line and batch options." );
  }

  return $self;
}

sub getCredentials
{
  # Parse the credentials file

  # Careful not to print any values found to output!
  my $self = shift;

  my $hasToken = $self->{'usetoken'};
  if( defined $self->{'credentials'} )
  {
    $util->openFile( "credentials", '<', $self->{'credentials'} );
    my $line;
    my $lineNumber;
    while( ($line, $lineNumber) = $util->getLine( "credentials" ) )
    {
      last if( $lineNumber == -1);

      my $errorStr = "Error parsing credentials file line $lineNumber: ";

      # Line format is key=value
      if( $line =~ m/^([a-zA-Z0-9]+)=(.+)$/ )
      {
        my $key   = lc($1);
        my $value = $2;

        $util->printDebug( "found $key in credentials file" );
        if ( !$hasToken )
        {
          $util->printDebug( "looking for username and password" );

          # Looking for username and password
          if( $key =~ m/^(accesskey|username|auth1)$/ )
          {
            # Found the username
            if( defined $self->{'username'} )
            {
              # This has been set multiple times...
              $util->userError( $errorStr . "$key already set to \"$self->{'username'}\"." );
            }
            $self->{'username'} = $value;
          }
          elsif( $key =~ m/^(secretkey|password|auth2)$/ )
          {
            # Found the password
            if( defined $self->{'password'} )
            {
              # This has been set multiple times...
              $util->userError( $errorStr . "$key already set to \"$self->{'password'}\"." );
            }
            $self->{'password'} = $value;
          }
          else
          {
            if ( lc($key) eq "token" )
            {
              $errorStr = $errorStr . "key \"token\" found in credentials file. If you intended to use token authentication, include the \"-token\" option.\n"; 
            }
            $util->userError( $errorStr . "unrecognized key \"$key\" found in credentials file when looking for username and password." );
          }
        }
        else
        {
          $util->printDebug( "looking for token" );
          # Looking for token
          if ( $key =~ m/^(token)$/ )
          {
            if( defined $self->{'token'})
            {
              # This has been set multiple times...
              $util->userError( $errorStr . "$key already set to \"$self->{'token'}\"." );
            }
            $self->{'token'} = $value;
          }
          else
          {
            $util->userError( $errorStr . "unrecognized key \"$key\" found in credentials file when looking for token." );
          }
        }
      }
      else
      {
        $util->userError( $errorStr . "line in wrong format." );
      }
    }
    $util->closeFile( 'credentials' );

    # Check we have both username and password
    # or that we have a token
    if ( !$hasToken)
    {
      if( not defined $self->{'username'} )
      {
        $util->userError( "Credentials file must have one of accesskey/username/auth1 keys." );
      }
      if( not defined $self->{'password'} )
      {
        $util->userError( "Credentials file must have one of secretkey/password/auth2 keys." );
      }
    }
    else 
    {
      if( not defined $self->{'token'} )
      {
        $util->userError( "Credentials file missing token." );
      }
    }

    # Success
    $util->printVerbose( "Credentials file valid." )
  }
  elsif( $QUIET )
  {
    $util->userError( "No credentials file passed to script, and cannot prompt because of -quiet. Exiting." );
  }
  else
  {
    # Prompt the user for the credentials
    $util->printOut( "Enter your credentials." );

    # add in the appropriate combination of  auth1/auth2 accesskey/secretkey username/password
    # for the service
    if ( !$hasToken )
    {
      my $auth1field = "";
      my $auth2field = "";
      if ( $self->{'tgtService'} eq "s3" )
      {
        $auth1field = "accesskey";
        $auth2field = "secretkey";
      }
      else
      {
        $auth1field = "username";
        $auth2field = "password";
      }

      my $auth1 = $util->promptUser( $auth1field . ": " );
      if( not $auth1 )
      {
        $util->printOut( "No $auth1field provided." );
        exit 1;
      }
      my $auth2 = $util->promptUser( $auth2field . ": ", 1 );
      if( not $auth2 )
      {
        $util->printOut( "No $auth2field provided." );
        exit 1;
      }
      $self->{'username'} = $auth1;
      $self->{'password'} = $auth2;
    }
    else
    {
      my $auth1 = $util->promptUser( "token:", 1 );
      if( not $auth1 )
      {
        $util->printOut( "No token provided." );
        exit 1;
      }
      $self->{'token'}    = $auth1;
    }
  }
}

sub setMode
{
  # Set the mode to batch/single/delete/test
  my $self = shift;
  my $newMode = shift;

  if( $mode ne "" )
  {
    $util->userError( "Modes Batch, Single (-source), Delete, and Test are mutually exclusive." );
  }

  if(    $newMode eq 'b' )
  {
    $mode = "batch";
  }
  elsif( $newMode eq 's' )
  {
    $mode = "single";
  }
  elsif( $newMode eq 'd' )
  {
    $mode = "delete";
  }
  elsif( $newMode eq 't' )
  {
    $mode = "test";
  }
  else
  {
    croak "setMode given bad mode $newMode";
  }

  $util->printDebug( "newMode $mode" );
}

sub checkSource
{
  # Check source attributes

  my $self = shift;
  if( $mode eq 'single' )
  {
    if( $compress and $self->isSourceCompressed($self->{'source'}{'name'}) )
    {
      $util->userError( "Compression not disabled but source $self->{'source'}{'name'} already compressed." 
                        . " Decompress or use the -nocompression option." );
    }
    $self->{'source'}{'basename'} = basename($self->{'source'}{'name'});
  }

  # If no tmpdir input then just set to current directory
  if( not defined $self->{'tmpdir'} )
  {
    $self->{'tmpdir'} = getcwd;
    $util->checkWriteDir( "tmpdir", $self->{'tmpdir'} );
  }
  # clean up the string, removing redundant '/'
  $self->{'tmpdir'} .= '/';
  $self->{'tmpdir'} =~ s/\/+/\//g;

  # cURL will dump its verbose output to a tmp file
  $self->{'curlout'} = $self->{'tmpdir'}.$scriptID.".curlout";
}

sub isSourceCompressed
{
  # Check if the source is already compressed
  
  my $self = shift;
  my $source = shift;
  if( ( $source =~ m/\.g(z|zip)$/) or
      (not system("gzip -t $source > /dev/null 2>&1")) )
  {
    $util->printVerbose( "Source file $source already compressed." );
    return 1;
  }
  else
  {
    return 0;
  }
}


############################################################################
#
# BATCH FILE HANDLING
#
############################################################################

sub checkBatchOption
{
  # Check the key/value pair from the batch option line
  # Return 0 on success, else an error message
  my $self        = shift;
  my $key         = shift;
  my $value       = shift;
  my $lineNumber  = shift;
  my $target_ref  = shift; # reference to temp %target hash, not the target object
  my $inputs      = shift;
  $util->printDebug(qq(batch option key "$key", value "$value" ));

  # Check that the option is recognized
  if (not exists $validBatchFileOptions{$key} )
  {
     return "option \"$key\" invalid.";
  }

  # If the option has already been set earlier it is an error
  if( defined $self->{$key} )
  {
    return "option \"$key\" already set. Remove duplicates.";
  }
  elsif( $value eq "" )
  {
    return "option \"$key\" has empty value. Comment out with '#'.";
  }
  # The batch option does not override command line input
  else
  {
    $self->{$key} = $value;
  }
  if( defined $inputs->{$key} )
  {
    $util->printVerbose( "Ignoring batch option $key (batch line $lineNumber) for cmd line value." );
    return 0; # Success, no error message
  }

  # Validate the value
  if( $key eq 'credentials' )
  {
    $util->checkReadFile( "batchcredentials", $value );
    $inputs->{'credentials'} = $value;
  }
  elsif( $key eq 'sourcedir' )
  {
    # Check the directory exists and is readable
    if( not (-r $value && -d _) )
    {
      return "sourcedir \"$value\" does not exist or is not readable";
    }
    $inputs->{'sourcedir'} = $value;
  }
  elsif( $key eq 'tmpdir' )
  {
    # Use a temporary storage directory
    $util->checkWriteDir( "tmpdir", $value );
    $inputs->{'tmpdir'} = $value;
  }
  elsif( $key eq 'service' )
  {
    $value = lc($value);
    # The keys of %services is a list of supported target platforms
    if( not (grep(/^$value$/, (keys %services)) ) )
    {
      return "service \"$value\" not supported";
    }
    $target_ref->{'service'} = $value;
    $inputs->{'service'} = $value;
  }
  elsif( $key =~ /^(url|container)$/ )
  {
    $inputs->{$key} = $value;
    $target_ref->{$key} = $value;

    if( $key eq "container" )
    {
      $util->checkContainer($inputs->{'container'});
    }
  }
  elsif( $key eq 'targetdir' )
  {
    $inputs->{$key} = $value;
    $target_ref->{$key} = $value;
  }
  elsif( $key =~ /^(nocompression|errorexit|usetoken)$/ )
  {
    if( $value =~ m/^on$/i )
    {
      if( $key eq 'nocompression' )
      {
        $util->printVerbose( "Compression disabled." );
        $compress = 0;
      }
      if( $key eq 'errorexit' )
      {
        $util->printVerbose( "Script will exit on any batch upload error." );
        $errorexit = 1;
      }
      if( $key eq 'usetoken' )
      {
        $inputs->{'usetoken'} = 1;
      }
    }
    elsif( $value =~ m/^off$/i )
    {
      if( $key eq 'compression' )
      {
        $compress = 1;
      }
      if( $key eq 'errorexit' )
      {
        $util->printVerbose( "Script will skip any batch upload error." );
        $errorexit = 0;
      }
      if( $key eq 'usetoken' )
      {
        $inputs->{'usetoken'} = 0;
      }
    }
    else
    {
      return "$key can only be 'on' or 'off'";
    }
  }
  elsif( $key =~ /^(threads|chunk|block)$/ )
  {
    # Integer values only
    if( not ( $value =~ m/^\d+$/ ) )
    {
      return "$key \"$value\" is not a valid integer value";
    }
    $inputs->{$key} = $value;
  }
  return 0; # Success, no error message
}

sub parseBatch
{
  # Parse the batch file

  my $self = shift;
  $util->openFile( "batch", '<', $self->{'batch'} );

  # Flags
  my $foundOptions = 0; # there was an options section
  my $foundUploads = 0; # there was an uploads section
  my $inOptions = 0;    # currently in options section
  my $inUploads = 0;    # currently in uploads section

  my $line;
  my $lineNumber;
  my %targetService = (); # hash to hold target service, url, container and
                          # possibly targetdir for creating target object

  # The upload entry hashes are stored as an array in the input object 
  # Initialize that array here
  # Entries of this array correspond to an upload object
  my $batch = MoveToCloud::Inputs->new();
  $self->{'uploads'} = [];

  # Go through the file one line at a time
  while( ($line, $lineNumber) = $util->getLine( "batch" ) )
  {
    last if( $lineNumber == -1);

    my $errorStr = "Error parsing batch file line $lineNumber: ";

    if( $inOptions )
    {
      # The line indicates end of options section
      if( $line eq $batchOptionsEnd )
      {
        $util->printDebug( "end of batch options" );
        $foundOptions = 1;
        $inOptions = 0;
        next;
      }
      # Line is one or more word characters '=' one or more anything
      elsif( $line =~ m/^(\w+)=(.+)$/ )
      {
        # Found an options line, check the key/value pair
        my $key = lc($1);
        my $value = $2;

        # Remove any quotations around the value, if any
        if( $value =~ m/^\"(.+)\"$/ or
            $value =~ m/^\'(.+)\'$/ )
        {
          $value = $1;
        }

        my $message = $batch->checkBatchOption( $key, $value, $lineNumber, \%targetService, $self );
        if( $message )
        {
          $util->userError( $errorStr . $message );
        }
      }
      else
      {
        $util->userError( $errorStr . "bad options line." );
      }
    }
    elsif( $inUploads )
    {
      # The line indicates end of options section
      if( $line eq $batchUploadsEnd )
      {
        $util->printDebug( "end of batch uploads" );
        $foundUploads = 1;
        $inUploads = 0;
        next;
      }

      # The source is the first field on the line
      if( $line =~ m/^\"(.+?)\"\s*(.*)$/ or # Line starts with a "quoted string"
          $line =~ m/^\'(.+?)\'\s*(.*)$/ or # Line starts with a 'quoted string'
          $line =~ m/^(\S+)\s*(.*)$/ )      # Line starts with a string
      {
        my $source = $1;
        $line = $2; # Store the rest of the line
        $util->printDebug("source: " . $source);
        $util->printDebug("line: " . $line);
        my $target;
        my $debugStr;

        # Check if there is a target specified
        if( $line ne "" )
        {
          if( $line =~ m/^\"(.+?)\"$/ or # Line is a "quoted string"
              $line =~ m/^\'(.+?)\'$/ or # Line is a 'quoted string'
              $line =~ m/^(\S+)$/ )      # Line is a string
          {
            $target = $1;
            $util->printDebug("target: " . $target);
          }
          else
          {
            $util->userError( $errorStr . "too many fields of upload entry." );
          }
        }

        $debugStr = "entry: source = \"$source\", ";

        if( defined $target )
        {
          $debugStr .= "target = \"$target\"";
        }
        else
        {
          $target = "";
          $debugStr .= "target = (empty)";
        }
        $util->printDebug( $debugStr );

        # Store the upload entry as a new object in the batch uploads array
        my $upload = MoveToCloud::BatchUpload->new($source, $target);
        push( @{$self->{'uploads'}}, $upload );
      }
      else
      {
        $util->userError( $errorStr . "bad uploads line." );
      }
    }
    elsif( $line eq $batchOptionsStart )
    {
      # The line indicates start of options section
      $util->printDebug( "start of batch options" );
      $inOptions = 1;
      next;
    }
    elsif( $line eq $batchUploadsStart )
    {
      # The line indicates start of uploads section
      $util->printDebug( "start of batch uploads" );
      $inUploads = 1;
      next;
    }
    else
    {
      # Invalid line
      $util->userError( $errorStr . "unrecognized section." );
    }
  }

  $util->closeFile( 'batch' );
  # End of file reached
  
  if ( $targetService{'service'} eq "s3" && $self->{'usetoken'} )
  {
    $util->userError( "Token authentication is incompatible with s3. Authenticate using username and password." );
  }
  
  # Service and URL options are required
  foreach my $key ('service','url','container')
  {
    if( not defined $self->{$key} )
    {
      $util->userError( "Batch file requires $key option to be set" );
    }
    # Code check: did we set them in the %target hash too?
    if( not defined $targetService{$key} )
    {
      croak "parseBatch did not set $key in target";
    }
  }

  # Create the target object corresponding to the service
  if ( $targetService{'service'} eq "softlayer")
  {
    $target = MoveToCloud::Softlayer->new( $targetService{'url'}, $targetService{'container'} );
  }
  elsif ( $targetService{'service'} eq "s3")
  {
    $target = MoveToCloud::S3->new( $targetService{'url'}, $targetService{'container'} );
  }
  if ( defined $targetService{'targetdir'})
  {
    $target->setTargetDir($targetService{'targetdir'});
  }
  # Check that the sources are valid
  $self->checkBatchUploads();
}

sub checkBatchUploads
{
  # Check the source files
  my $self = shift;
  my $i = 1; # Iterator, tracks the source #
  foreach my $upload_ref ( @{$self->{'uploads'}} )
  {
    $upload_ref->setId($i);
    $upload_ref->checkEachUpload($self);
  }
  continue
  {
    $i++;
  }
  my $numUploads = $i - 1;
  $util->printVerbose( "Batch uploads count: $numUploads" );
}

package MoveToCloud::Target;

use 5.010;
use strict;
use warnings;
use File::Basename;
use Carp;
use Data::Dumper;

sub new
{
  my $class = shift;
  my $self = { 'url'              => shift,
               'container'        => shift,
               'name'             => shift,
               'username'         => "",
               'password'         => "",
               'dir'              => "",
               'is_dir'           => "",
               #  'baseurl'          => "",
               'token'            => "",
               'targetdir'        => "",
               'curl'             => undef,
               'service_urls'     => undef
             };
  bless $self, $class;
  return $self;
}

sub getUrl
{
  my $self = shift;
  return $self->{'url'};
}

sub setUsername
{
  my $self = shift;
  $self->{'username'} = shift;
}

sub setPassword
{
  my $self = shift;
  $self->{'password'} = shift;
}

sub setContainer
{
  my $self = shift;
  $self->{'container'} = shift;
}

sub setUrl
{
  my $self = shift;
  $self->{'url'} = shift;
}

sub setTargetDir
{
  my $self = shift;
  $self->{'targetdir'} = shift;
}

sub checkTarget
{
  # Check the cloud connection inputs

  my $inputs = shift;
  my %targetService = ();

  # Non-batch mode gets target info from input string
  # Batch mode got it from the batch file earlier
  if( $mode ne "batch" )
  {
    # Set up the target object 
    # This will result in the hash having the following keys:
    # 'service'       - service name (softlayer, s3)
    # 'url'           - actual URL (resolved below if input was an alias)
    # 'container'     - container/bucket name where target is stored
    # 'name'          - full path in the container/bucket,
    #                   where the file will be available upon completion
    # 'dir'           - full path of the pseudo-directory the file will be in
    # 'is_dir'        - flag indicating the input target name was just the
    #                   directory, and the name will be copied from the source

    $inputs->{'target'}       =~ /^(.+?)::(.+?)::(.+?)::(.+)$/;
    if( not defined $4 )
    {
      $util->userError( "Target string invalid. Confirm 4 fields are present." );
    }

    ($targetService{'service'},
     $targetService{'url'},
     $targetService{'container'},
     $targetService{'name'}      ) = (lc($1), $2, $3, $4);

    # The keys of %services is a list of supported target platforms
    # Check if the target service is supported
    if( not (grep(/$targetService{'service'}/, (keys %services))) )
    {
      $util->userError( "Target service \"$targetService{'service'}\" not supported. Use -list to see services." );
    }

    # Create a new object for the service initialized with service name, url, container and target name
    if ( $targetService{'service'} eq "softlayer")
    {
      $target = MoveToCloud::Softlayer->new( $targetService{'url'}, $targetService{'container'}, $targetService{'name'} );
    }
    elsif ( $targetService{'service'} eq "s3")
    {
      $target = MoveToCloud::S3->new( $targetService{'url'}, $targetService{'container'}, $targetService{'name'} );
    }

    # Save the input URL
    $inputs->{'url'} = $target->getUrl();

    # Check container name value
    $util->checkContainer($target->{'container'});

    # Clean up the target path string, and modify the target name if it will be compressed
    $target->cleanupTargetName($inputs->{'source'}{'basename'});

    # We should now have the target's name, directory, and parts directory
    if( $DEBUG )
    {
      # Print the target settings
      my $debugStr = "Target details:\n";
      foreach my $field (sort keys %$target)
      {
        my $value;
        if( $field =~ m/^(username|password)$/ )
        {
          # Do not print the username/password
          $value = $mask;
        }
        elsif ( defined $target->{$field} )
        {
          $value = $target->{$field};
        }
        if ( defined $value )
        {
          $debugStr .= "'$field' = '$value'\n";
        }
      }
      chop $debugStr; # remove trailing ','
      $util->printDebug( $debugStr );
    }
  }

  if( $target->{'service'} eq "softlayer" )
  {
    $softlayer = 1;
  }
  elsif( $target->{'service'} eq "s3" )
  {
    $s3 = 1;
  }

  # Set the username and password if provided
  if ( not defined $inputs->{'token'} )
  {
    $target->setUsername($inputs->{'username'});
    $target->setPassword($inputs->{'password'});
  }
  # Validate the service and url, and check the connection
  $target->validateUrl($inputs);
  # Initialize data needed for curl requests
  $target->{'curl'} = MoveToCloud::Curl->new( $inputs->{'curlout'}, 
                                              $target->{'username'}, 
                                              $target->{'password'},
                                              $target->{'token'} );

  # Finish setting up the service (authenticate with server, check container)
  $target->setup($inputs);

  # Check if target file locations already exist
  if( $mode eq 'single' )
  {
    my $errorMsg = $target->checkThisTarget($inputs->{'credentials'}, $inputs->{'usetoken'}, $inputs->{'url'});
    if( $errorMsg ne "" )
    {
      $util->userError( $errorMsg );
    }
  }
  elsif( $mode eq 'batch' )
  {
    foreach my $upload_ref ( @{$inputs->{'uploads'}} )
    {
      next if( $upload_ref->{'skip'} );
      $upload_ref->useThisUpload( $target, $inputs );
      my $errorMsg = $target->checkThisTarget($inputs->{'credentials'}, $inputs->{'usetoken'}, $inputs->{'url'});
      if( $errorMsg )
      {
        $upload_ref->batchSkipPromptAndHandleResponse( $errorMsg, $inputs );
      }
    }
  }
  elsif( $mode eq 'test' )
  {
    my $errorMsg = $target->checkThisTarget($inputs->{'credentials'}, $inputs->{'usetoken'}, $inputs->{'url'});
    if( $errorMsg ne "" )
    {
      $util->userError( $errorMsg );
    }
    $util->printOut( "Test successful. Upload may proceed." );
    $util->cleanup();
    exit 0;
  }
  elsif( $mode eq 'delete' )
  {
    $target->checkDelete();
  }
  else
  {
    croak "unrecognized mode \"$mode\"";
  }
}

sub cleanupTargetName
{
  # Clean up the path string
  # remove redundant '/'s, remove the leading '/'
  my $self            = shift;
  my $source_basename = shift;

#  $self->{'name'} = "/$self->{'name'}";
  $self->{'name'} =~ s/\/+/\//g;
  $self->{'name'} =~ s/^\///;

  if( $self->{'name'} =~ m/\/$/ or
      $self->{'name'} eq "" )
  {
    # If the target path ends in '/' then it is a directory
    $self->{'dir'} = $self->{'name'};
    $self->{'is_dir'} = 1;

   if( $mode eq 'single' )
   {
     # The target file will be named after the source
     $self->{'name'} = ($self->{'dir'}).($source_basename);
   }
  }
  else
  {
    # File will be renamed
    $self->{'is_dir'} = 0;
    if( $self->{'name'} =~ /\// )
    {
      $self->{'dir'} = dirname($self->{'name'}).'/';
    }
    else
    {
      $self->{'dir'} = "";
    }
  }

  if( $compress )
  {
    # Uploaded file will be compressed with gzip
    if( not($self->{'name'} =~ m/\.g(z|zip)$/) )
    {
    # Add .gz if the target input doesn't already use it
      $self->{'name'} = "$self->{'name'}.gz";
    }
  }
  $util->printDebug("cleaned up target name: " .  $self->{'name'});
}

sub validateUrl
{
  # Validate the service and url, and check the connection
  my $self   = shift;
  my $inputs = shift;
  if( exists $self->{'service_urls'}{$self->{'url'}} )
  {
    # The URL input is actually a tag, save the actual URL
    $self->{'url'} = $self->{'service_urls'}{$self->{'url'}};
  }
  else
  {
    # Check if the URL input is valid
    my %service_hash = reverse %{$self->{'service_urls'}};
    # Check if the custom endpoint is secure
    my $inputUrl = $self->{'url'};
    my $char = '/';
    $inputUrl =~ s/\Q$char\E?$/$char/; # add a backslash to the end of the url if it's missing
    if( not $self->{'url'} =~ m/^https:\/\// )
    {
      # Warn user that endpoint is NOT secure
      if( not $util->askBool( "Endpoint does not use secure HTTP. " .
          "Upload will NOT be encrypted. Continue anyway?", $inputs ) )
      {
        $util->userError( "Not continuing due to insecure connection." );
      }
      $inputUrl =~ s/http/https/; 
    }
    if ( defined $inputs->{'token'} )
    {
      # using a token, so modify the input url to check if it corresponds to a valid 
      # softlayer service url
      $inputUrl =~ s/(.*\.net).*/$1/;
      $inputUrl = $inputUrl . "/auth/v1.0";
    }
    if ( not ($service_hash{$inputUrl}) )
    {
      # Custom endpoints not allowed
      $util->userError( "Custom endpoints not allowed with ". ucfirst($self->{'service'}). ". Use one of the tags from '$scriptName -list'." );
    }
  }
}

sub checkThisTarget
{
  # Check the target name and parts path are available
  my $self        = shift;
  my $credentials = shift;
  my $token       = shift;
  my $url         = shift;
  my $errorMsg    = "";
  my @listOfFiles = $self->listFiles( $self->{'dir'} );

  # If the list is empty then the target is available
  if( not defined $listOfFiles[0] )
  {
    return $errorMsg;
  }

  # Get a list of existingfiles
  # Regex: beginning_of_line (name or part_XXX) end_of_line
  my @existingFiles = grep( /^$self->{'name'}$/, @listOfFiles );
  if( $softlayer )
  {
    push( @existingFiles, grep(/^$self->{'parts_prefix'}(\d)+\d\d$/, @listOfFiles) );
  }

  if( $VERBOSE or $DEBUG )
  {
    # Print any existing files to diag logs
    foreach my $file (@existingFiles)
    {
      $util->printVerbose( "File exists: $file" );
    }
  }

  # Check if the target or any parts exist, if so: print how to delete then exit
  if( grep( /^$self->{'name'}$/, @existingFiles) )
  {
    $errorMsg = $self->howToDelete( 'target', $credentials, $token, $url );
  }
  elsif( (defined $existingFiles[0]) and
         ($existingFiles[0] ne "") )
  {
    # target name not there but array not empty, must be a part
    $errorMsg = $self->howToDelete( 'part', $credentials, $token, $url );
  }
  return $errorMsg;
}

sub howToDelete
{
  # Print the command to delete given target
  my $self        = shift;
  my $deleteType  = shift;
  my $credentials = shift;
  my $token       = shift;
  my $url         = shift;

  my $delim = "::";

  my $targetStr = $self->{'service'}    . $delim .
                  $url                  . $delim .
                  $self->{'container'}  . $delim;

  my $credsOption = "";
  if ( $token )
  {
     $credsOption = " -token";
  }
  if( $credentials )
  {
    $credsOption = " -creds " . $credentials . $credsOption;
  }

  my $deleteStatement = $scriptName  .
                        $credsOption .
                        " -delete -target ";
  my $message;

  if( $deleteType eq 'target' )
  {
    $message    = qq(Target "$self->{'name'}" already exists. To delete it use:\n);
    $targetStr .= $self->{'name'};
  }
  elsif( $deleteType eq 'part' )
  {
    $message    = "Target's part(s) already exist. To delete the parts use:\n";
    $targetStr .= $self->{'parts_dir'};
  }
  else
  {
    croak "howToDelete: invalid delete type " . $deleteType;
  }

  $message .= $deleteStatement . $targetStr;
  return $message;
}

sub checkDelete
{
  # Check if target is a directory or single file and prepare it for deleting
  my $self = shift;
  if( $self->{'is_dir'} )
  {
    # Delete an entire directory
    # First get a list of all the files
    my @filesList = $self->listFiles( $self->{'dir'} );
    if( not defined $filesList[0] )
    {
      $util->userError( "Delete target directory \"$self->{'dir'}\" already empty." );
    }

    # Save the list of files we will be deleting later
    # We will do a BULK DELETE of the files later
    $self->{'parts_list'} = \@filesList;
  }
  else
  {
    # Prepare the single file for deleting using method specific to service
    $self->prepareFileDelete();
  }
}

sub deleteTarget
{
  # Delete the target
  my $self     = shift;
  my $scriptID = shift;
  my $inputs   = shift;

  # Create the list of files to delete
  # This is used both for the prompt and the SoftLayer request
  my @files;
  my $fileListStr = "";
  my $numFiles = 0;

  # Having a parts_list means one of two things:
  #   - the target was a manifest file
  #   - the target was a directory

  if( defined $self->{'parts_list'} )
  {
    # Add each file to the list
    $numFiles = push( @files, @{$self->{'parts_list'}});
    $fileListStr .= join("\n", @{$self->{'parts_list'}});
  }

  if( $self->{'is_dir'} )
  {
    # If the target was a directory then the parts_list are all we delete
    chomp $fileListStr;
  }
  else
  {
    # The target was a single file, add it to the list
    push( @files, $self->{'name'} );
    $fileListStr .= $self->{'name'};
    $numFiles++;
  }

  # We have the list, now prompt the user
  if( $util->askBool( "Delete the following files?\n$fileListStr\n$numFiles total", $inputs ) )
  {
    my $numDeletes = $self->bulkDelete( $scriptID, $inputs, @files );
    $util->printOut( "Successfully deleted $numDeletes files." );
  }
  else
  {
    $util->userError( "Delete aborted by user.\n" .
                      "TIP: The -yes option can be used to automatically confirm deletion of files." );
  }

  return 0;
}

sub listFiles
{
  # Return a list of files with the given prefix on the target
  my $self     = shift;
  my $prefix   = shift;

  if( not defined $prefix )
  {
    croak "listFiles needs prefix input";
  }

  $util->printDebug( "listing files with prefix \"" . $prefix . "\"" );

  # call the subroutine specific to Softlayer or S3
  my @list = $self->listFilesForService( $prefix );

  if( $DEBUG )
  {
    my $debugStr = "list of files with prefix \"$prefix\":";
    $debugStr .= "\n" . join("\n", @list);
    $util->printDebug( $debugStr );
  }
  return @list;
}


package MoveToCloud::S3;
@MoveToCloud::S3::ISA = qw(MoveToCloud::Target); # S3 inherits from Target

use 5.010;
use strict;
use warnings;
use Carp;
use URI::Escape;
use Encode qw(encode_utf8);
use Digest::MD5;
use Data::Dumper;
use POSIX qw(strftime);

BEGIN
{
  if( eval "require Digest::SHA" )
  {
    Digest::SHA->import('sha256_hex', 'hmac_sha256', 'hmac_sha256_hex');
    return 1;
  }
  else
  {
    print STDERR "Required Perl module Digest::SHA missing.\n";
    print STDERR "Check Perl -version is 5.10 or higher.\n";
    print STDERR "Users with RHEL 6.X:\n";
    print STDERR "yum install perl-Digest-SHA\n";
    exit 1;
  }
}

sub new
{
  my $class = shift;
  # inherit the fields from Target class
  my $self  = $class->SUPER::new(shift, shift, shift, shift);

  $self->{'service'}           = "s3";
  $self->{'host'}              = "";
  $self->{'bucket'}            = $self->{'container'};
  $self->{'request'}           = "";
  $self->{'sourceFile'}        = undef;
  $self->{'sourceData'}        = undef;
  $self->{'targetPath'}        = "";
  $self->{'requestParams'}     = undef;
  $self->{'headers'}           = undef;
  $self->{'signature'}         = "";
  $self->{'timestamp'}         = "";
  $self->{'timestampAMZ'}      = "";
  $self->{'encodedPath'}       = "";
  $self->{'payloadHash'}       = "";
  $self->{'cQueryStr'}         = "";
  $self->{'cRequest'}          = "";
  $self->{'cRequestHash'}      = "";
  $self->{'cHeadersStr'}       = "";
  $self->{'signedHeadersStr'}  = "";
  $self->{'credsScope'}        = "";
  $self->{'stringToSign'}      = "";
  $self->{'authStr'}           = "";
  $self->{'hashAlgorithm'}     = "AWS4-HMAC-SHA256";
  $self->{'requestTerm'}       = "aws4_request";

  $self->{'service_urls'} = \%s3_urls;

  bless $self, $class;
  return $self;
}

sub setup
{
  my $self    = shift;
  my %regions = reverse %s3_urls;   # useful for derefencing

  # Finish initialization here after the url has been validated
  $self->{'endpoint'}          = $self->{'url'};
  $self->{'region'}            = $regions{$self->{'url'}};

  # Make the host url:
  # https://<endpoint>/<bucket>
  $self->{'endpoint'} =~ /^(https?):\/\/(.+)$/;
  $self->{'host'}     =  "$2";
  $self->{'endpoint'} .= "/$self->{'bucket'}";

  # Set up the access key and secret key
  $self->{'accesskey'}         = $self->{'username'};
  $self->{'secretkey'}         = $self->{'password'};

  my @response = $self->getCheckBucket();

  # Check for the continue or "no containers" error code
  (my $httpCode, my $httpMsg) = $util->httpCodeCheck("400-499", @response);
  if( $httpCode )
  {
    # This script cannot create S3 buckets
    if( $httpCode == 404 )
    {
      $util->userError( "S3 bucket $self->{'container'} does not exist." );
    }
    else
    {
      $util->userError( "S3 bucket check failed: \"$httpMsg\"" );
    }
  }
  $util->printVerbose( "S3 account credentials and bucket are valid." );
}

sub listFilesForService
{
  my $self   = shift;
  my $prefix = shift;

  my @list = ();
  my $moreFiles = 1;  # Are there more files to be returned?
  my $marker = "";    # Continue listing from here

  while( $moreFiles )
  {
    my @query    = $self->getFileList( $prefix, $marker );
    my @response = $self->{'curl'}->curl( @query );

    (my $httpCode, my $httpMsg) = $util->httpCodeCheck(200, @response);
    if( not $httpCode )
    {
        $util->userError( "S3 list file query failed: \"$httpMsg\"" );
    }

    # The XML data is the last line of the response
    my $xmlData   = $response[$#response];
    # Now split the data between each tag
    my @xmlValues = split( /></, $xmlData );

    # Parse all the Key values (file names)
    my @keys = grep( /^Key>/, @xmlValues );
    foreach my $key (@keys)
    {
      $key =~ /Key>(.*)<\/Key/;
      push( @list, $1 );
    }

    # There are more files to get if IsTruncated
    if( grep( /IsTruncated>true</, @xmlValues ) )
    {
        $moreFiles = 1;
        $marker    = $list[$#list];
    }
    else
    {
        $moreFiles = 0;
    }
  }
  return @list;
}

sub prepareFileDelete
{
  # Prepare delete for single file
  
  my $self      = shift;
  my @filesList = $self->listFiles( $self->{'name'} );

  if( (not defined $filesList[0]) or
      (not grep( /^$self->{'name'}$/, @filesList ) ) )
  {
    $util->userError( "Delete target \"$self->{'name'}\" does not exist." );
  }
}

sub bulkDelete
{
  # Perform a bulk delete request
  # This will delete multiple objects in a single request
  
  my $self     = shift;
  my $scriptID = shift; 
  my $inputs   = shift; 
  my @files    = @_;

  my $numFiles = ($#files+1);
  $util->printDebug( "bulk delete of $numFiles files" );

  # See http://docs.aws.amazon.com/AmazonS3/latest/API/multiobjectdeleteapi.html
  my $multiDeleteFile = $inputs->{'tmpdir'}.$scriptID.".delete";
  my @query = $self->getMultiDelete( $multiDeleteFile, @files );
  my @response = $self->{'curl'}->curl( @query );

  if( !$keepFile )
  {
     unlink $multiDeleteFile;
  }
  # Search for any "Key" values (those are errors)
  if( my @lines = grep( /Key/, @response ) )
  {
      $util->userError( "S3 multi object delete error response:/n$lines[$#lines]" );
  }

  $util->printDebug( "bulk delete successfully delete $numFiles" );

  return $numFiles;
}

sub putFile
{
  my $self         = shift;
  my $fileToUpload = shift;
  my $target_name  = shift;

  my @query    = $self->getPut( $target_name, $fileToUpload );
  my @response = $self->{'curl'}->curl( @query );

  # Put request will return Continue first, then a blank line, then the
  # message we are interested in
  (my $httpCode, my $httpMsg) = $util->httpCodeCheck("200", @response);
  if( not $httpCode )
  {
   # Upload failed
   return "Upload to \"$target_name\" failed: $httpMsg"; 
  }
  return 0;
}

sub dump
{
  # Dump given members

  my $self   = shift;
  my $member = shift;

  printDebug( "S3 dump '$member':\n$self->{$member}" );
}

sub cleanupQuery
{
  # Reset any query-specific values from the object

  my $self = shift;

  $self->{'request'}          = "";
  $self->{'url'}              = "";
  $self->{'sourceFile'}       = undef;
  $self->{'sourceData'}       = undef;
  $self->{'targetPath'}       = "";
  $self->{'requestParams'}    = undef;
  $self->{'headers'}          = undef;
  $self->{'signature'}        = "";
  $self->{'timestamp'}        = "";
  $self->{'timestampAMZ'}     = "";
  $self->{'encodedPath'}      = "";
  $self->{'payloadHash'}      = "";
  $self->{'cQueryStr'}        = "";
  $self->{'cRequest'}         = "";
  $self->{'cRequestHash'}     = "";
  $self->{'cHeadersStr'}      = "";
  $self->{'signedHeadersStr'} = "";
  $self->{'credsScope'}       = "";
  $self->{'stringToSign'}     = "";
  $self->{'authStr'}          = "";
}

sub stampTime
{
  # Make the timestamps using the current time

  my $self = shift;

  my @time = gmtime(time);

  $self->{'timestamp'}    = strftime("%Y%m%d",         @time);
  $self->{'timestampAMZ'} = strftime("%Y%m%dT%H%M%SZ", @time);
}

sub mkCanonURI
{
  # Step 2 in http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html

  my $self = shift;

  my $path = $self->{'targetPath'};

  my $encodedPath = "";

  # Prepend the (encoded) bucket name
  $encodedPath = '/'                             .
                 (uri_escape($self->{'bucket'})) .
                 '/'                             .
                 join("/", map { uri_escape($_) } split("/", $path));

  $self->{'encodedPath'} = $encodedPath;
}

sub mkCanonQueryStr
{
  # Step 3 in http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html

  my $self = shift;

  my $pParams = $self->{'requestParams'};

  my %encodedParams;
  my $canonQueryStr = "";

  # URI-encode each parameter name and value
  %encodedParams = map { uri_escape($_) => uri_escape( $pParams->{$_} ) } keys %{$pParams};

  $canonQueryStr = join("&",
                        map { defined $encodedParams{$_} ? $_ . "=" . $encodedParams{$_} : $_ . "="}
                        sort keys %encodedParams);
  $self->{'cQueryStr'} = $canonQueryStr;
}

sub mkPayloadHash
{
  # Make a hash of the data to be sent

  my $self = shift;

  if( defined $self->{sourceFile} )
  {
    # Make a new digest and digest the source file
    open( my $fh, '<', $self->{sourceFile} )
      or croak "failed to open source to read";
    my $digester = Digest::SHA->new(256);
    $digester->addfile($fh);
    $self->{'payloadHash'} = $digester->hexdigest;
    close $fh;
  }
  elsif( defined $self->{sourceData} )
  {
    # Make a new digest and digest the source data
    my $digester = Digest::SHA->new(256);
    $digester->add($self->{'sourceData'});
    $self->{'payloadHash'} = $digester->hexdigest;
  }
  else
  {
    # There is no additional data, just hash an empty string
    $self->{'payloadHash'} = sha256_hex( "" );
  }
}

sub mkHeadersStrings
{
  # Make the headers strings for the request

  my $self = shift;

  my %headers = %{$self->{'headers'}};

  my $canon   = "";
  my $signed  = "";

  # Loop through the headers hash, sorted lexically
  foreach my $tag (sort keys %headers)
  {
    # We want to create the canon and signed headers strings
    # A lot of the work is to clean up the value for the canon string

    my $value = $headers{$tag};

    # Lowercase tag
    $tag   =  lc($tag);

    # Remove leading and trailing whitespace from the value
    $value =~ s/^\s*//;
    $value =~ s/\s*$//;

    # Remove redundant whitepsace EXCEPT when enclosed in quotes
    my $cleanValue;
    while( $value =~ m/(.*?)(['"])(.*)/ms )
    {
      my $pre  = $1;
      my $mark = $2;
      my $post = $3;

      $pre =~ s/\s+/ /g;
      $cleanValue .= $pre;

      if( $mark eq '"' )
      {
        $post =~ m/(.*?)"(.*)/ms;
        my $quote = $1;
        my $rest = $2;
        $cleanValue .= "\"$quote\"";
        $value = $rest;
      }
      else # $mark eq '
      {
        $post =~ m/(.*?)'(.*)/ms;
        my $quote = $1;
        my $rest = $2;
        $cleanValue .= "'$quote'";
        $value = $rest;
      }
    }
    $value =~ s/\s+/ /g;
    $cleanValue .= $value;

    $canon  .= "$tag:$cleanValue\n";
    $signed .= "$tag;";
  }

  # There is an extra ';' at the end of the signed string
  chop $signed;

  $self->{'cHeadersStr'} = $canon;
  $self->{'signedHeadersStr'} = $signed;
}

sub mkCanonRequest
{
  # Create the canonical request

  my $self = shift;

  $self->{'cRequest'} = ( $self->{'request'}          . "\n" .
                          $self->{'encodedPath'}      . "\n" .
                          $self->{'cQueryStr'}        . "\n" .
                          $self->{'cHeadersStr'}      . "\n" .
                          $self->{'signedHeadersStr'} . "\n" .
                          $self->{'payloadHash'} );

  $self->{'cRequestHash'} = sha256_hex($self->{'cRequest'});
}

sub mkCredentialsScope
{
  # Make the credential scope string

  my $self = shift;

  $self->{'credsScope'} = $self->{'timestamp'}            . '/' .
                          encode_utf8($self->{'region'})  . '/' .
                          encode_utf8($self->{'service'}) . '/' .
                          $self->{'requestTerm'};
}

sub mkStringToSign
{
  # Create the String to Sign

  my $self = shift;

  $self->{'stringToSign'} = $self->{'hashAlgorithm'}  . "\n" .
                            $self->{'timestampAMZ'}   . "\n" .
                            $self->{'credsScope'}     . "\n" .
                            $self->{'cRequestHash'};
}

sub mkSignature
{
  # Calculate the request signature

  my $self = shift;

  my $kSecret     = 'AWS4' . $self->{'secretkey'};
  my $kDateBin    = hmac_sha256( $self->{'timestamp'},    $kSecret      );
  my $kRegionBin  = hmac_sha256( $self->{'region'},       $kDateBin     );
  my $kServiceBin = hmac_sha256( $self->{'service'},      $kRegionBin   );
  my $kSigningBin = hmac_sha256( $self->{'requestTerm'},  $kServiceBin  );

  $self->{'signature'} = hmac_sha256_hex( $self->{'stringToSign'}, $kSigningBin );
}

sub mkAuthorizationStr
{
  # Format the authorization string

  my $self = shift;

  $self->{'authStr'} = "$self->{'hashAlgorithm'} "                            .
                       "Credential=$self->{'accesskey'}/$self->{'credsScope'}, " .
                       "SignedHeaders=$self->{'signedHeadersStr'}, "          .
                       "Signature=$self->{'signature'}";
}

sub authorize
{
  # Make the authorization header string for the request

  my $self = shift;

  $self->stampTime();
  $self->mkPayloadHash();
  $self->mkCanonURI();
  $self->mkCanonQueryStr();

  $self->{'headers'}->{'Host'}                 = $self->{'host'};
  $self->{'headers'}->{'x-amz-date'}           = $self->{'timestampAMZ'};
  $self->{'headers'}->{'x-amz-content-sha256'} = $self->{'payloadHash'};

  $self->mkHeadersStrings();
  $self->mkCanonRequest();
  $self->mkCredentialsScope();
  $self->mkStringToSign();
  $self->mkSignature();
  $self->mkAuthorizationStr();

  $self->{'headers'}->{'Authorization'} = $self->{'authStr'};
}

sub mkTargetURL
{
  # Make the target URL for the cURL request

  my $self = shift;

  my $url = $self->{'endpoint'} . '/' .
            $self->{'targetPath'};

  if( defined $self->{'requestParams'} )
  {
    my %params = %{$self->{'requestParams'}};
    $url .= '?';
    $url = $url . join("&",
                map { defined $params{$_} ? ($_ . "=" . $params{$_}) : $_ } keys %params);
  }

  $self->{'url'} = $url;
}

sub getCurlHeaders
{
  # Make a list of curl header options

  my $self = shift;

  my %headers = %{$self->{'headers'}};

  my @options;
  foreach my $header (keys %headers)
  {
    push( @options, "-H \"$header: $headers{$header}\"" );
  }

  if( $self->{'sourceFile'} )
  {
    push( @options, "-T $self->{'sourceFile'}" );
  }
  elsif( $self->{'sourceData'} )
  {
    push( @options, "-d \"$self->{'sourceData'}\"" );
  }

  return @options;
}

sub mkQuery
{
  # Create the query

  my $self = shift;

  $self->authorize();
  $self->mkTargetURL();

  my @options = $self->getCurlHeaders();

  my @query = ( $self->{'url'},
                "-X $self->{'request'} -i",
                @options );

  $self->cleanupQuery();

  return @query;
}

sub getCheckBucket
{
  # Create the query to check if the bucket exists and the target path
  # is available.

  my $self    = shift;

  $self->{'request'}        = 'GET';
  $self->{'requestParams'}  = { 'max-keys' => 1 };

  my @query = $self->mkQuery();
  return $self->{'curl'}->curl( @query );
}

sub getFileList
{
  # Create the file list query

  my $self      = shift;
  my $prefix    = shift;
  my $marker    = shift;

  $self->{'request'}        = 'GET';
  $self->{'requestParams'}  = { 'prefix'    => $prefix,
                                'max-keys'  => 100      };

  if( (defined $marker) and ($marker ne "") )
  {
    $self->{'requestParams'}->{'marker'} = $marker;
  }

  return $self->mkQuery();
}

sub getPut
{
  # Create the query to put a file

  my $self    = shift;
  my $target  = shift;
  my $source  = shift;

  # Get the MD5 sum of the source
  if( open( my $fh, '<', $source ) )
  {
    my $md5 = Digest::MD5->new;
    $md5->addfile($fh);
    my $checkSum = $md5->b64digest;
    $self->{'headers'}->{'Content-MD5'} = "$checkSum==";
    close $fh;
  }
  else
  {
    $util->printVerbose( "Could not open \"$source\" for MD5 checksum calculation. Data validation will not occur." );
  }

  $self->{'request'}        = 'PUT';
  $self->{'sourceFile'}     = $source;
  $self->{'targetPath'}     = $target;

  return $self->mkQuery();
}

sub getInitMultipartUpload
{
  # Create the query to initiate a multipart upload

  my $self    = shift;
  my $target  = shift;

  $self->{'request'}        = 'POST';
  $self->{'targetPath'}     = $target;
  $self->{'requestParams'}  = { 'uploads' => undef };

  return $self->mkQuery();
}

sub getAbortMultipartUpload
{
  # Create the query to abort a multipart upload

  my $self    = shift;
  my $target  = shift;
  my $id      = shift;

  $self->{'request'}        = 'DELETE';
  $self->{'targetPath'}     = $target;
  $self->{'requestParams'}  = { 'uploadId' => $id };

  return $self->mkQuery();
}

sub getCompleteMultipartUpload
{
  # Create the query to complete the multipart upload operation

  my $self          = shift;
  my $target        = shift;
  my $multiPartID   = shift;
  my $tmpFile       = shift;
  my @partsList     = @_;
  # We need to make the list of ETags
  my $partsListXML = "<CompleteMultipartUpload>";
  for( my $i = 0; $i <= $#partsList; $i++ )
  {
    if( (not defined $partsList[$i]->{'etag'}) or
        ($partsList[$i]->{'etag'} eq "") )
    {
      croak "no etag on part $i";
    }
    $partsListXML .= "<Part>" .
                     "<PartNumber>".($i + 1)."</PartNumber>" .
                     "<ETag>$partsList[$i]->{'etag'}</ETag>" .
                     "</Part>";
  }
  $partsListXML .= "</CompleteMultipartUpload>";
  $util->printDebug ( $partsListXML );

  open( my $tmpFH, '>', $tmpFile );
  print $tmpFH $partsListXML;
  close $tmpFH;

  $self->{'request'}        = 'POST';
  $self->{'sourceFile'}     = $tmpFile;
  $self->{'targetPath'}     = $target;
  $self->{'requestParams'}  = { 'uploadId' => $multiPartID };

  return $self->mkQuery();
}

sub getPutPart
{
  # Create the query to put a part file

  my $self    = shift;
  my $target  = shift;
  my $id      = shift;
  my $source  = shift;
  my $part    = shift;

  # Get the MD5 sum of the source
  if( open( my $fh, '<', $source ) )
  {
    my $md5 = Digest::MD5->new;
    $md5->addfile($fh);
    my $checkSum = $md5->b64digest;
    $self->{'headers'}->{'Content-MD5'} = "$checkSum==";
    close $fh;
  }
  else
  {
    $util->printVerbose( "Could not open \"$source\" for MD5 checksum calculation. Data validation will not occur." );
  }

  $self->{'request'}        = 'PUT';
  $self->{'sourceFile'}     = $source;
  $self->{'targetPath'}     = $target;
  $self->{'requestParams'}  = { 'uploadId'   => $id,
                                'partNumber' => $part };

  return $self->mkQuery();
}

sub getMultiDelete
{
  # Create the query for multi-object-delete

  my $self    = shift;
  my $tmpFile = shift;
  my @files   = @_;

  # Make the list of files to delete
  my $list = "<Delete>" .
             "<Quiet>true</Quiet>";
  for( my $i = 0; $i <= $#files; $i++ )
  {
    $list .= "<Object>" .
             "<Key>$files[$i]</Key>" .
             "</Object>";
  }
  $list   .= "</Delete>";

  open( my $tmpFH, '>', $tmpFile );
  print $tmpFH $list;
  close $tmpFH;

  # Get an MD5 checksum of the list
  my $md5 = Digest::MD5->new;
  open( $tmpFH, '<', $tmpFile );
  $md5->addfile($tmpFH);
  close $tmpFH;
  my $checkSum = $md5->b64digest;

  $self->{'request'}                  = 'POST';
  $self->{'sourceFile'}               = $tmpFile;
  $self->{'headers'}->{'Content-MD5'} = "$checkSum==";
  $self->{'requestParams'}            = { 'delete' => undef };

  return $self->mkQuery();
}

# Softlayer inherits from Target
package MoveToCloud::Softlayer;
@MoveToCloud::Softlayer::ISA = qw(MoveToCloud::Target);

use 5.010;
use strict;
use warnings;
use File::Basename;
use Encode qw(encode_utf8);
use Carp;
use Digest::MD5;
use Data::Dumper;

sub new
{
  my $class               = shift;
  # inherit the fields from Target class
  my $self                = $class->SUPER::new(shift, shift, shift, shift);
  $self->{'service'}      = "softlayer";
  $self->{'service_urls'} = \%softlayer_urls;
  bless $self, $class;
  return $self;
}

############################################################################
#
# SUBROUTINES FOR CURL QUERIES
#
############################################################################

sub getCheckAuthentication
{
  my $self     = shift;
  my $hasToken = shift;
  my @query;
  if ( !$hasToken )
  {
    @query = ( $self->{'url'},
               '-X GET', '-i', '-v',
               "-H \"X-Auth-User: $self->{'username'}\"",
               "-H \"X-Auth-Key: $self->{'password'}\"" );
  }
  else
  {
    @query = ( $self->{'url'},
               '-X HEAD', '-i',
               "-H \"X-Auth-Token: $self->{'token'}\"" );
  }
  my @response = $self->{'curl'}->curl( @query );
  return @response;
}

sub getCheckContainerExists
{
  my $self  = shift;
  my @query = ( "$self->{'url'}?format=json",
                '-X GET', '-i',
                "-H \"X-Auth-Token: $self->{'token'}\"" );
  my @response = $self->{'curl'}->curl( @query );
  return @response;
}

sub getFileList
{
  my $self   = shift;
  my $prefix = shift;
  my $marker = shift;
  my @query  = ( "$self->{'url'}?prefix=$prefix" .
                 "&limit=100" . $marker,
                 "-X GET -i",
                 "-H \"X-Auth-Token: $self->{'token'}\"" );
  my @response = $self->{'curl'}->curl( @query );
  return @response;
}

sub putContainer
{
  my $self  = shift;
  my @query = ( "$self->{'url'}/$self->{'container'}",
                '-X PUT', '-i',
                "-H \"X-Auth-Token: $self->{'token'}\"");
  my @response = $self->{'curl'}->curl( @query );
  return @response;
}

sub headDescribeFile
{
  my $self  = shift;
  my @query = ( "$self->{'url'}/$self->{'name'}",
                "-X HEAD -I",
                "-H \"X-Auth-Token: $self->{'token'}\"" );
  my @response = $self->{'curl'}->curl( @query );
  return @response;
}

sub getMultiDelete
{
  my $self        = shift;
  my @query;
  if ( defined $self->{'encodedList'})
  {
    @query = ( "$self->{'baseurl'}?bulk-delete",
               "-X POST -i",
               "-H \"X-Auth-Token: $self->{'token'}\"",
               "-H \"Content-Type: text/plain\"",
               "--data '$self->{'encodedList'}'" );
  }
  elsif ( defined $self->{'filesToDelete'})
  {
    @query = ( "$self->{'baseurl'}?bulk-delete",
               "-X POST -i",
               "-H \"X-Auth-Token: $self->{'token'}\"",
               "-H \"Content-Type: text/plain\"",
               "--data-binary '\@$self->{'filesToDelete'}'" );
  }
  my @response = $self->{'curl'}->curl( @query );
  return @response;
}


############################################################################
#
# SUBROUTINES
#
############################################################################

sub setup
{
  # Authenticate with the Swift server, check the container and target path
  my $self   = shift;
  my $inputs = shift;

  $util->printVerbose( "Setting up Softlayer access ..." );
  my @response;
  my $httpCode;
  my $httpMsg;

  # Try authentication with username and password
  if ( not defined $inputs->{'token'} )
  {
    $util->printDebug( "authenticating softlayer" );
    @response = $self->getCheckAuthentication(0);
    ($httpCode, $httpMsg) = $util->httpCodeCheck(401, @response);
    if( $httpCode )
    {
      # Response says Unauthorized
      $util->userError( "SoftLayer authentication error. Check credential values." );
    }

    # Save the input

    # Get the X-Auth-Token and X-Storage-URL from the response
    foreach my $line (@response)
    {
       chomp $line;
       if( $line =~ m/X-Auth-Token: (.+)$/ )
       {
          $self->{'token'} = $1;
       }
       elsif( $line =~ m/X-Storage-Url: (.+)$/ )
       {
          # URL for future requests
          $self->{'url'} = $1;
       }
       else
       {
          next;
       }
    }
    # Was it successful?
    if( (not defined($self->{'token'})) || (not defined($self->{'url'})) )
    {
       my $reasonMsg = &httpStatusMsg($response[0]);
       $util->userError( "SoftLayer authentication error. Reason phrase = \"$reasonMsg\"" );
    }
    $util->printDebug( "authentication successful, url = \"$self->{'url'}\"" );
  }
  else
  {
    $util->printDebug( "authenticating softlayer with token" );
    # Try authentication with user provided token and X-Storage-Url
    $self->{'token'} = $inputs->{'token'};
    @response = $self->getCheckAuthentication(1);

    ($httpCode, $httpMsg) = $util->httpCodeCheck("400,401,403", @response);
    if ( $httpCode ) 
    {
       # Response says Unauthorized
       $util->userError( "SoftLayer authentication error. Check token and url values." );
    }
    $util->printDebug( "authentication successful" );
  }
  # Check the given container exists
  $util->printDebug( "checking softlayer container \"$self->{'container'}\"" );
  @response = $self->getCheckContainerExists();

  # Check for the continue or "no containers" error code
  ($httpCode, $httpMsg) = $util->httpCodeCheck("200,204", @response);
  if( not $httpCode)
  {
    # Bad response
    croak "listing containers failed with \"$httpMsg\"";
  }

  my $containerExists = 0; # Flag indicating if the container already exists
  if( not ($httpCode == 204) )
  {
    # There are containers, parse the json data
    my $jsonData = $response[$#response]; # last line of the response is the data

    # replace all [ ] { } , with newlines
    $jsonData =~ s/\[|\]|{|}|,/\n/g;

    # split the remaining data along newlines (also trim the leading/trailing whitespace)
    my @jsonData = split( /\s*\n+\s*/, $jsonData );

    # Now search the names values for the target container
    # Names data is in the format "name": "<value>"
    if( grep( /^\"name\": \"$self->{'container'}\"/, @jsonData ) )
    {
      $containerExists = 1;
    }
    # Else we need to create it
  }

  if( not $containerExists )
  {
    if( $mode eq 'delete' )
    {
      $util->userError( "Container \"$self->{'container'}\" does not exist." );
    }

    # Container does not exist
    if( not $util->askBool( "Container \"$self->{'container'}\" does not exist. Create container?", $inputs ) )
    {
      $util->userError( "SoftLayer container \"$self->{'container'}\" does not exist." );
    }
    $util->printVerbose( "Creating container $self->{'container'}" );
    $self->putContainer();
    (my $httpCode, my $httpMsg) = $util->httpCodeCheck("200-202", @response);
    if( not $httpCode )
    {
      $util->userError( "SoftLayer container creation error. Reason phrase = \"$httpMsg\"" );
    }
  }

  # Add the container to the URL to make future calls simpler
  $self->{'baseurl'} = $self->{'url'};
  $self->{'url'} = "$self->{'url'}/$self->{'container'}";
  $util->printDebug( "target url with container name \"$self->{'url'}\"" );
}

sub cleanupTargetName
{
  my $self = shift;
  $self->SUPER::cleanupTargetName(shift);

  # SoftLayer requires parts and a manifest file
  # We will name the parts ~/<target_name>.parts/<target_name>_<part_number>
  # 'parts_dir'     - the pseudo-directory of the file parts
  # 'parts_prefix'  - the name of parts files minus the number
  if ( $self->{'service'} eq "softlayer" )
  {
    $self->{'parts_dir'} = "$self->{'name'}.parts/";
    $self->{'parts_prefix'} = ($self->{'parts_dir'}).(basename($self->{'name'})).'_';
  }
}

sub listFilesForService
{
  my $self   = shift;
  my $prefix = shift;

  my $marker = "";
  my @list   = ();

  while(1)
  {
    my @response = $self->getFileList( $prefix, $marker );
    (my $httpCode, my $httpMsg) = $util->httpCodeCheck("200-299", @response);
    if( not $httpCode )
    {
      $util->printDebug( "no files under $prefix" );
      return @list;
    }
    last if( $httpCode == 204 );

    # Remove response headers, last one is Date:
    while(1)
    {
      my $line = shift @response;
      last if( $line =~ m/^\s*Date: / );
    }

    push( @list, grep( /^$prefix/, @response ) );
    $marker = "&marker=" . $list[$#list];
  }
  return @list;
}

sub prepareFileDelete
{
  # Prepare delete for target that is a single file
  my $self = shift;
  my %target_metadata;
   
  # We will try and get its metadata. This can tell us if it exists
  # and if it is a manifest file.
  if( not $self->describeFile( $self->{'name'}, \%target_metadata ) )
  {
    $util->userError( "Delete target \"$self->{'name'}\" does not exist." );
  }

  if( defined $target_metadata{'X-Object-Manifest'} )
  {
    # This is a SoftLayer manifest file
    # We will do a BULK DELETE of the file and its parts later
    # For now just get the list of the parts

    # The X-Object-Manifest value will be the parts prefix, starting
    # with the container name. Trim that off then save it to %target
    $target_metadata{'X-Object-Manifest'} =~ /^$self->{'container'}\/(.+)$/;
    $self->{'parts_prefix'} = $1;
    $self->{'parts_dir'}    = (dirname($self->{'parts_prefix'})).'/';

    my @prefixList = $self->listFiles( $self->{'parts_prefix'} );
    my @partsList  = grep( /^$self->{'parts_prefix'}(\d+)\d\d$/, @prefixList );
    $self->{'parts_list'} = \@partsList;
  }
}

sub describeFile
{
  # Get the meta data of a file in storage
  my $self     = shift;
  my $file     = shift;
  my $hdrs_ref = shift;

  if( not defined $hdrs_ref )
  {
    croak "describeFile needs file and headers hash reference inputs";
  }

  $util->printDebug( "describing $file" );

  my @response = $self->headDescribeFile();

  (my $httpCode, my $httpMsg) = $util->httpCodeCheck("200-299,404", @response);
  if( not $httpCode )
  {
    croak "SoftLayer describe object failed. Reason phrase = \"$httpMsg\"";
  }
  elsif( $httpCode == 404 )
  {
    return 0;
  }

  foreach my $line (@response)
  {
    chomp $line;
    # Get the response header tag and value from the line
    # Regex: beginning_of_line (tag): spaces (value) end_of_line
    if( $line =~ m/^(\S+):\s+(.+)$/ )
    {
      my $tag   = $1;
      my $value = $2;

      # We are only interested in X-headers, the Etag, and the content length
      if( $tag =~ m/^(x-\S+|etag|Content-Length)$/i )
      {
        $hdrs_ref->{$tag} = $value;
      }
    }
  }

  if( $DEBUG )
  {
    my $debugStr = "list of response headers:";
    foreach my $tag (keys %{$hdrs_ref})
    {
      $debugStr .= "\n$tag = $hdrs_ref->{$tag}";
    }
    $util->printDebug( $debugStr );
  }

  return 1;
}

sub bulkDelete
{
  # Perform a bulk delete request
  # This will delete multiple objects in a single request
  
  my $self     = shift;
  my $scriptID = shift; # this param is not used... but required for s3.
  my $inputs   = shift;
  my @files    = @_;

  my $numFiles = ($#files+1);
  $util->printDebug( "bulk delete of $numFiles files" );
  
  # See http://docs.openstack.org/api/openstack-object-storage/1.0/content/bulk-delete.html
  my $encodedList = "";
  $encodedList = join( "\n",  map { "$self->{'container'}/" . encode_utf8($_) } @files);

  if ( $numFiles < 999 ) 
  {
    $self->{'encodedList'} = $encodedList;
  }
  # curl argument list may be too long, so store arguments in a file if > 999 parts
  else
  {
    $self->{'filesToDelete'} = $inputs->{'tmpdir'} . "filesToDelete";
    $util->openFile( 'filesToDelete', '>', $self->{'filesToDelete'} );
    print {$filehandles{"filesToDelete"}} $encodedList;
    $util->closeFile( 'filesToDelete');
  }

  my @response = $self->getMultiDelete();
  my @lines = grep( /^Number Deleted:/, @response );
  if( not ($lines[0] =~ m/^Number Deleted: (\d+)$/) )
  {
    croak "bulk delete bad request";
  }
  my $numDeleted = $1;
  if( $numDeleted != $numFiles )
  {
    $util->userError( "SoftLayer bulk delete request error. Tried to delete $numFiles, only successful for $numDeleted." );
  }

  if ( defined $self->{'encodedList'} ) 
  {
    undef $self->{'encodedList'};
  }
  elsif ( defined $self->{'filesToDelete'} )
  {
    unlink( $self->{'filesToDelete'} or warn "Could not unlink $self->{'filesToDelete'}: $!");
  }

  $util->printDebug( "bulk delete successfully delete $numFiles" );

  return $numFiles;
}

sub putFile
{
  # Upload/put the file into remote storage
  # Returns 0 for success or an error message
  my $self        = shift;
  my $source      = shift;
  my $target_name = shift;
  my @options     = @_;

  if( not defined $target_name )
  {
    croak "putFile needs source and target inputs";
  }

  if( $DEBUG )
  {
    my $debugMsg = "put $source to $target_name";
    if( defined $options[0] )
    {
      $debugMsg .= ", options = ";
      $debugMsg .= join (",", @options);
    }
    $util->printDebug( $debugMsg );
  }

  # Calculate the checksum for data validation
  if( not $util->openFile( "md5", '<', $source, 0 ) )
  {
    my $md5 = Digest::MD5->new;
    $md5->addfile($filehandles{'md5'});
    my $checkSum = $md5->hexdigest;
    push( @options, "-H \"ETag: $checkSum\"" );
    $util->closeFile( "md5" );
  }
  else
  {
    $util->printVerbose( "Could not open \"$source\" for MD5 checksum calculation. Data validation will not occur." );
  }

  my $attempt = 0;
  my $success = 0;
  my $httpMsg;
  while( $attempt < MoveToCloud::Constants::MAX_PUT_ATTEMPTS )
  {
    my @response;
    my @query;
    if( not defined $options[0] )
    {
      @query = ( "$self->{'url'}/$target_name",
                 "-X PUT -i",
                 "-H \"X-Auth-Token: $self->{'token'}\"",
                 "-T $source" );
    }
    else
    {
      @query = ( "$self->{'url'}/$target_name",
                 "-X PUT -i",
                 "-H \"X-Auth-Token: $self->{'token'}\"",
                 @options,
                 "-T $source" );
    }
    @response = $self->{'curl'}->curl( @query );

    # Put request will return Continue first, then a blank line, then the
    # message we are interested in
    (my $httpCode, $httpMsg) = $util->httpCodeCheck("201", @response);
    if( not $httpCode )
    {
      $attempt++;
      sleep MoveToCloud::Constants::ATTEMPT_SLEEP;
      next;
    }
    $success = 1;
    last;
  }
  if( not $success )
  {
    return "SoftLayer put object failed after $attempt attempts. Reason phrase = \"$httpMsg\"";
  }

  $util->printDebug( "put $target_name successful" );
  return 0;
}

package MoveToCloud::UploadTask;

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw[min max];
use Data::Dumper;

my $childOkMsg = "OK";

sub new
{
  my $class = shift;

  my $self = { 'inputs'      => shift,
               'target'      => shift,
               'filehandles' => shift,  
               'rc'          => 0, 
               'errorMsg'    => "",
               'pids'        => [] 
             };

  bless $self, $class;
  return $self;
}

sub setUploadInfoId
{
  my $self = shift;
  $self->{'uploadInfo'}{'id'} = sprintf('%.3d', shift);   # upload task number (formatted to 3 digits)
}

sub setup
{
  my $self     = shift;
  my $uploadId = shift;
  my $inputs   = $self->{'inputs'};
  my $target   = $self->{'target'};

  # Track all upload task information via a hash so we can pass it around.
  my %uploadInfo = ( 'id'           => "",   # upload task number (formatted to 3 digits)
                     'workingDir'   => "",    # temporary storage directory (subdir of $inputs{'tmpdir'})
                     'inFH'         => undef, # input (source file) file handle
                     'outFH'        => undef, # output (current part file) file handle
                     'fileList'     => [],    # list of files used for this upload (for cleanup)
                     'partCount'    => 0,     # number of parts
                     'singlePart'   => 0,     # is there only one part
                     'partsList'    => undef, # array of childInfo for each part, used to make the etag list
                     'uploaded'     => 0,     # bytes currently uploaded
                     'currPart'     => 0,     # current part info reference
                     'multiPartID'  => ""    # s3 multipart upload ID
                   );

  # Part information tracker hash skeleton.
  my %partInfo   = ( 'id'           => 0,     # part number (formatted to 3 digits)
                     'buffer'       => "",    # buffer for reading from the source file in blocks
                     'bufferLen'    => 0,     # length of data read into buffer
                     'size'         => 0,     # (current) total size
                     'tag'          => "",    # part tag, indicates upload
                     'source'       => "",    # part source file path
                     'compressed'   => "",    # part compressed source file path
                     'uploadSize'   => 0,     # size of file to upload
                     'target'       => "",    # part target name
                     'pipes'        => undef, # part pipes hash reference
                     'pid'          => 0      # part child process ID
                   );

  # Part children need a couple of pipes to provide feedback
  my %pipesInfo  = ( 'rFeedback'    => undef, # message reader (parent)
                     'wFeedback'    => undef, # message writer (child)
                     'rUploadSize'  => undef, # size reader (parent)
                     'wUploadSize'  => undef  # size writer (child)
                   );

  $self->{'uploadInfo'} = \%uploadInfo;
  $self->{'childInfo'}  = ();
  $self->{'partInfo'}   = \%partInfo;
  $self->{'pipesInfo'}  = \%pipesInfo;

  my $uploadInfo = $self->{'uploadInfo'};
  
  # Make the working directory
  $self->setUploadInfoId($uploadId);
  $uploadInfo->{'workingDir'} = $inputs->{'tmpdir'}.${scriptID}.'.'.$uploadInfo->{'id'};
  $self->{'rc'} = mkdir( $uploadInfo->{'workingDir'}, 0700 );
  if( not $self->{'rc'} )
  {
    $self->{'errorMsg'} = "Failed to create temp directory $uploadInfo->{'workingDir'}: $!";
    $self->cleanupUpload( $self->{'$errorMsg'} );
    return __LINE__;
  }

  # Prepare to start reading from the source
  if( $self->{'errorMsg'} = $util->openFile( 'source', '<', $inputs->{'source'}{'name'}, 0 ) )
  {
    $self->cleanupUpload( $self->{'$errorMsg'} );
    return __LINE__;
  }
  my $inFH = $self->{'filehandles'}{'source'}; # Quick filehandle reference
  $uploadInfo->{'inFH'} = $inFH;
}


sub simpleUpload
{
  # Just do a simple upload, not a multipart

  my $self = shift;

  my $errorMsg;
  my $target     = $self->{'target'};
  my $inputs     = $self->{'inputs'};
  my $uploadInfo = $self->{'uploadInfo'};
  my $rc         = $self->{'rc'};

  if( $s3 )
  {
    # Abort the multipart upload
    my @query    = $target->getAbortMultipartUpload( $target->{'name'}, $uploadInfo->{'multiPartID'} );
    my @response = $target->{'curl'}->curl( @query );
    (my $httpCode, my $httpMsg) = $util->httpCodeCheck("204", @response);
    if( not $httpCode )
    {
      $util->printDebug( "S3 multipart upload abort failed: $httpMsg" );
    }
    $util->printDebug( "aborted multipart upload $uploadInfo->{'multiPartID'}" );
    $uploadInfo->{'multiPartID'} = "";
  }

  my $fileToUpload = $inputs->{'source'}{'name'};

  if( $compress )
  {
    my $compressedName = $uploadInfo->{'workingDir'} . '/' .
                         $inputs->{'source'}{'basename'}            . '.gz';
    $util->printDebug( "compressing $inputs->{'source'}{'name'} into " . $compressedName );
    push( @{$uploadInfo->{'fileList'}}, $compressedName );
    # Compress the chunk with the OS command gzip
    # To capture both output and RC use qx()
    $errorMsg = qx(gzip -c $inputs->{'source'}{'name'} > $compressedName 2>&1);
    $rc = $? >> 8; # to get real RC, shift value by 8
    if( $rc == 1 )
    {
      # GZip returned an error
      chomp $errorMsg;
      $errorMsg = "Compression of source for \"$target->{'name'}\" failed: $errorMsg";
      if( !$keepFile )
      {
        # We only want to keep the files around if debugging
        unlink( $compressedName );
      }
      $self->cleanupUpload( $errorMsg );
      return __LINE__;
    }
    $util->printDebug( "done compressing" );
    $fileToUpload = $compressedName;
  }

  # Ready to upload
  # Make sure the file size is defined
  my $uploadSize = $util->retry( \&stat, $fileToUpload );

  $util->printDebug( "uploading " . $fileToUpload .
               "(" . $uploadSize . " bytes) to " .
               $target->{'name'} );

  # Call putFile for the appropriate target
  if( $errorMsg = $target->putFile($fileToUpload, $target->{'name'}) )
  {
    # Upload failed
    if( !$keepFile )
    {
      # We only want to keep the file around if debugging
      unlink( $fileToUpload );
    }
    $self->cleanupUpload( $errorMsg );
    return __LINE__;
  }
}

sub uploadSourceToTarget
{ 
  # Upload the source file to the target
  #
  # The process is as follows:
  #
  # open source file for reading
  # if s3
  #   initiate multipart upload
  # do
  #   read chunk
  #   open part file
  #   write to part file
  #   close part file
  #   start child
  #     compress if enabled
  #     put part to target
  #     exit child
  #   reap any finished children
  #   check number of threads running
  #   if max threads
  #     wait for a child to finish
  #     reap child
  # while more source file to read
  # close source file
  # if s3
  #   complete multipart upload
  # else if softlayer
  #   create manifest file
  # return

  # Cleanup requires closing the in and out file handles.
  # There will only be one file open for reading and one for writing at a time.
  
  my $self = shift;
  $self->setup(shift);

  my $uploadInfo = $self->{'uploadInfo'};
  my $partInfo   = $self->{'partInfo'};
  my $inputs     = $self->{'inputs'};
  my $target     = $self->{'target'};
  my $errorMsg   = $self->{'errorMsg'};
  my $rc         = $self->{'rc'};
  my $childInfo  = $self->{'childInfo'};

  $util->printVerbose( "Starting upload process for $inputs->{'source'}{'name'} to $target->{'name'}" );

  while( $partInfo->{'bufferLen'} = sysread($uploadInfo->{'inFH'},
                                    $partInfo->{'buffer'},
                                    &bytesToCopy(0,$chunkSize))
       )
  {
    # Start of a new part
    $uploadInfo->{'partCount'}++;

    if( $uploadInfo->{'singlePart'} )
    {
      # This should never be set by this point
      # It is initialized to 0, and the only case it is TRUE should not loop
      croak "programming error: singlePart true";
    }
    
    (my $part, my $pipes) = $self->createParts();

    # Loop started with reading out one block.
    # Write that block to the chunk and then read and write more blocks until
    # chunk size is reached.
    
    my $outFH = $self->{'filehandles'}{$part->{'tag'}}; # Quick file handle reference

    while(1)
    {
      # Write out the buffer to the part file
      $rc = syswrite( $outFH, $part->{'buffer'}, $part->{'bufferLen'} );
      if( not defined $rc )
      {
        $errorMsg = "Error writing to file \"$part->{'source'}\": $!";
        $self->cleanupUpload( $errorMsg );
        return __LINE__;
      }
      elsif( $rc != $part->{'bufferLen'} )
      {
        croak "error writing $part->{'tag'}, wrote $self->{'rc'}/$part->{'bufferLen'} bytes";
      }
      $part->{'size'} += $part->{'bufferLen'};

      # Check if the chunk size has been reached
      last if( $part->{'size'} >= $chunkSize );
    } continue {
      # Read another block
      last if( not $part->{'bufferLen'} = sysread($uploadInfo->{'inFH'},
                                                  $part->{'buffer'},
                                                  &bytesToCopy($part->{'size'}, $chunkSize))
             );
    }
    if( not defined $part->{'bufferLen'} )
    {
      # Something went wrong reading from the source file
      $errorMsg = "Reading from $inputs->{'source'}{'name'} failed: $!";
      $self->cleanupUpload( $errorMsg );
      return __LINE__;
    }

    # Done writing out this part
    $util->closeFile( $part->{'tag'} );
    undef $uploadInfo->{'outFH'};
    undef $outFH;
    undef $part->{'buffer'};
    $util->printDebug( "$part->{'tag'}: wrote $part->{'size'} to \"$part->{'source'}\"" );

    # Two types of upload:
    # - simple (5GB limit, single upload)
    # - large object / multipart
    
    if( ($uploadInfo->{'partCount'} == 1 ) and
        ($part->{'size'} < $chunkSize) )
    {
      # Read the whole file but it fits in only one part
      # Therefore cancel large object upload procedure
      # Instead do simple upload
      $uploadInfo->{'singlePart'} = 1;
      $util->printVerbose( "Source \"$inputs->{'source'}{'basename'}\" small enough for single upload." );
      $self->simpleUpload();
    }
    else
    {
      # Open a pipe for receiving messages back from the upcoming child,
      # and another for passing back the size of the file that was uploaded
      if( (not pipe($pipes->{'rFeedback'},   $pipes->{'wFeedback'})) or
          (not pipe($pipes->{'rUploadSize'}, $pipes->{'wUploadSize'})) )
      {
        $errorMsg = "Opening communication pipe failed: $!";
        $self->cleanupUpload( $errorMsg );
        return __LINE__;
      }

      # Spawn a child process to compress and upload this chunk
      my $pid; # process ID
      $childInfo->{'rFeedback'}   = $pipes->{'rFeedback'};
      $childInfo->{'rUploadSize'} = $pipes->{'rUploadSize'};
      if( $pid = fork() )
      {
        # Parent
        $childInfo->{'pid'} = $pid;  # store the PID
        push( @{$uploadInfo->{'partsList'}}, $childInfo );
        undef $childInfo;
        close( $pipes->{'wFeedback'}   ); # the parent is read-only
        close( $pipes->{'wUploadSize'} ); # the parent is read-only
        $util->printDebug( "$part->{'tag'}: spawned child $pid" );
        push( @{$self->{'pids'}}, $pid );
      }
      elsif( defined $pid )
      {
        # Child
        $isChild = 1;
        $SIG{PIPE} = "IGNORE";
        close( $pipes->{'rFeedback'}   ); # the child is write-only
        close( $pipes->{'rUploadSize'} ); # the child is write-only

        my $fileToUpload = $part->{'source'};

        # Exit values:
        # 0 - success
        # 1 - GZip error
        # 2 - upload error
        # 3 - interrupted

        if( $DEBUG )
        {
          # Child needs its own debug file
          my $topMessage = "$part->{'tag'} debug file\n";
          $topMessage .= '-' x 80 . "\n";
          $errorMsg = $util->openFile( "debug", '>', "$uploadInfo->{'workingDir'}/$part->{'tag'}.debug", 0, $topMessage );
          if( $errorMsg )
          {
            croak "open child debug failed";
          }
          $util->printDebug( "child thread started" );
        }

        # Child also needs its own curlout file
        $inputs->{'curlout'} = "$uploadInfo->{'workingDir'}/$part->{'tag'}.curlout";
        $target->{'curl'}->setCurlout($inputs->{'curlout'});
        $util->printDebug( "child curlout file: " . $inputs->{'curlout'} );

        $curlStmt = 0;

        if( $compress )
        {
          $util->printDebug( "compressing $part->{'source'} into $part->{'compressed'}" );
          # Compress the chunk with the OS command gzip
          # To capture both output and RC use qx()
          $errorMsg = qx(gzip -c $part->{'source'} > $part->{'compressed'} 2>&1);
          $rc = $? >> 8; # to get real RC, shift value by 8
          if( $rc == 1 )
          {
            # GZip returned an error
            chomp $errorMsg;
            if( !$keepFile )
            {
              # We only want to keep the files around if debugging
              unlink( $part->{'source'} or warn "Could not unlink $part->{'source'}: $!");
              unlink( $part->{'compressed'} or warn "Could not unlink $part->{'compressed'}: $!");
            }
            close $pipes->{'wUploadSize'};
            close $pipes->{'wFeedback'};
            exit MoveToCloud::Constants::CHILD_ERR_GZIP;
          }
          $util->printDebug( "done compressing" );
          if( !$keepFile )
          {
            unlink( $part->{'source'} or warn "Could not unlink $part->{'source'}: $!");
          }
          $fileToUpload = $part->{'compressed'};
        }

        # Ready to upload
        # Make sure the file size is defined
        $part->{'uploadSize'} = $util->retry( \&stat, $fileToUpload );
        $util->printDebug( "uploading " . $fileToUpload . 
                     "(" . $part->{'uploadSize'} . " bytes)" );

        print {$pipes->{'wUploadSize'}} $part->{'uploadSize'};
        close $pipes->{'wUploadSize'};

        # call putFile subroutine specific to Softlayer/S3 upload task 
        $self->putFile( $pipes, $fileToUpload, $part );

        close $pipes->{'wFeedback'};
        $util->printDebug( "done uploading" );

        if( $DEBUG )
        {
          $util->printDebug( "child successful" );
          $util->closeFile( "debug" );
        }
        if ( !$keepFile )
        {
          # We only want to keep the file around if debugging
          unlink( $fileToUpload );
          unlink( $inputs->{'curlout'}.$curlStmt );
          unlink( $inputs->{'curlout'});
        }
        exit MoveToCloud::Constants::CHILD_ERR_NO;
      }
      else
      {
        $util->printWarn( "failed to fork: " . $! );
        $util->printWarn( "trying wait ..." );
        while(1)
        {
          my $zombie = wait();
          last if( $zombie == -1 );
          $util->printWarn( "reaped $zombie with rc $?" );
        }

        die "failed to fork: $!";
      }

      # Loop through the list of children and check if any are finished.
      # This is non-blocking and will clean up children finished by this time.
      do {
        $util->printDebug( "checking for zombies from the " . ($#{$self->{'pids'}}+1) . " remaining children" );
        $pid = waitpid(-1, POSIX::WNOHANG);
        $rc = $? >> 8;
        if( $pid > 0 )
        {
          $errorMsg = $self->reapChild( $pid, $rc );
          if( $errorMsg )
          {
            # Something went wrong
            $self->cleanupUpload( $errorMsg );
            return __LINE__;
          }
          next;
        }
        $util->printDebug( "no zombie children to reap" );
      } while $pid > 0;

      # Check if we are at the max allowed number of threads.
      if( $#{$self->{'pids'}} == $maxThreads-1 )
      {
        # At max number of threads, must wait for a child to finish.
        $util->printDebug( "max threads reached, must wait and reap a child" );
        $pid = wait();
        $rc = $? >> 8;
        if( $pid == -1 )
        {
          die "max threads reached but no children to reap";
        }
        $errorMsg = $self->reapChild( $pid, $rc );
        if( $rc or $errorMsg )
        {
          # Something went wrong
          $self->cleanupUpload( $errorMsg );
          return __LINE__;
        }
      }
    }
  } continue {
    undef $uploadInfo->{'currPart'};
  }

  if( not defined $partInfo->{'bufferLen'} )
  {
    # Something went wrong
    $errorMsg = "Reading from $inputs->{'source'}{'name'} failed: $!";
    $self->cleanupUpload( $errorMsg );
    return __LINE__;
  }

  # Wait for all the children to finish
  while( $self->{'pids'}[0] )
  {
    my $childPID = $self->{'pids'}[0];
    waitpid( $childPID, 0 );
    $rc = $? >> 8;
    if( $childPID == -1 )
    {
      die "reap target invalid";
    }
    $errorMsg = $self->reapChild( $childPID, $rc );
    if( $rc or $errorMsg )
    {
      # Something went wrong
      $self->cleanupUpload( $errorMsg );
      return __LINE__;
    }
  }

  $util->printDebug( "finished " . $uploadInfo->{'partCount'} . " uploads, " .
               "total size " . $uploadInfo->{'uploaded'} . " bytes" );

  if( $s3 and
      ($uploadInfo->{'uploaded'} <= (10 * MoveToCloud::Constants::MEGABYTES)) )
  {
    $uploadInfo->{'singlePart'} = 1;
    $util->printVerbose( "Compressed file size small enough for simple upload." );
    $util->printVerbose( "Cancelling multipart upload then doing simple upload." );
    $self->simpleUpload( $uploadInfo );
  }

  if( $uploadInfo->{'singlePart'} )
  {
    # Single part upload complete
    $util->printOut( "Successfully uploaded to \"" . $target->{'name'} . "\"" );
  }
  else
  {
    # Complete large object / multipart upload
    $util->printDebug( "all uploader children finished" );
    my $uploadCompleteFile = "$uploadInfo->{'workingDir'}/uploadComplete";
    $errorMsg = $self->completeMultipartUpload();
    unlink $uploadCompleteFile;
    if ( !$errorMsg )
    {
      $util->printOut( "Successfully split file into " . $uploadInfo->{'partCount'} .
                       " chunks and uploaded to \"" . $target->{'name'} . "\"" );
    }
  }

  $self->cleanupUpload( "" );
  return 0;
}

sub createParts
{
  my $self       = shift;
  my $uploadInfo = $self->{'uploadInfo'};
  my $inputs     = $self->{'inputs'};
  my $target     = $self->{'target'};
  my $errorMsg   = $self->{'errorMsg'};

  # Create a part. Copy the %partInfo hash skeleton.
  my %part                  = %{$self->{'partInfo'}};
  my %pipes                 = %{$self->{'pipesInfo'}};
  $uploadInfo->{'currPart'} = \%part;
  $part{'pipes'}            = \%pipes;

  $part{'id'} = sprintf('%.3d',$uploadInfo->{'partCount'});

  # Quick reference tag for this part.
  # Example: U020P005 is upload #20, part #5
  $part{'tag'} = "U$uploadInfo->{'id'}P$part{id}";

  # Source chunk name
  $part{'source'} = "$uploadInfo->{'workingDir'}/$inputs->{'source'}{'basename'}_$part{'id'}";
  $util->printDebug( "$part{'tag'}: source chunk name \"$part{'source'}\"" );

  if( $compress )
  {
    # Compressed chunk name
    $part{'compressed'}= "$uploadInfo->{'workingDir'}/$inputs->{'source'}{'basename'}.gz_$part{id}";
    $util->printDebug( "$part{'tag'}: compressed chunk name \"$part{'compressed'}\"" );
  }

  if( $softlayer )
  {
    # Target chunk name
    $part{'target'} = $target->{'parts_prefix'} . $part{'id'};
    $util->printDebug( "$part{'tag'}: target part name \"$part{'target'}\"" );
  }

  # Copy the chunk to its own file $part{'source'}
  if( $errorMsg = $util->openFile( $part{'tag'}, '>', $part{'source'}, 0 ) )
  {
    $self->cleanupUpload( $errorMsg );
    return __LINE__;
  }

  my $outFH = $self->{'filehandles'}{$part{'tag'}}; # Quick file handle reference
  $uploadInfo->{'outFH'} = $outFH;
  push( @{$uploadInfo->{'fileList'}}, $part{'source'} );

  return ( \%part, \%pipes );
}

sub bytesToCopy
{
  # Calculate the correct number of bytes to read for this block

  my $currLen = shift;
  my $maxSize = shift;
  if( $currLen > $maxSize )
  {
    croak "block copy logic error: $currLen > $maxSize";
  }
  return min(($maxSize - $currLen),$blockSize);
}

sub cleanupUpload
{
  # Cleanup after upload task

  my $self       = shift;
  my $errorMsg   = shift;
  my $uploadInfo = $self->{'uploadInfo'};
  my $target     = $self->{'target'};

  if( not defined $errorMsg )
  {
    croak "cleanupUpload missing inputs";
  }

  if( $errorMsg )
  {
    $util->printWarn( "Upload $uploadInfo->{'id'} failed: $errorMsg" );
  }

  $util->printVerbose( "Cleaning up upload $uploadInfo->{'id'}" );

  # Close the filehandle writing to the part file
  if( defined $uploadInfo->{'currPart'} )
  {
    $util->closeFile( $uploadInfo->{'currPart'}->{'tag'} );
  }

  # Close the filehandle reading from the source
  $util->closeFile('source');

  # Interrupt any children
  if( defined $self->{'pids'}[0] )
  {
    my $pidList = join(" ", @{$self->{'pids'}});
    $pidList = "($pidList)";
    $util->printDebug( "reaping children: $pidList" );
    kill( 'TERM', @{$self->{'pids'}} );
    # make sure they all exit
    while( my $pid = wait )
    {
      last if( $pid == -1 );
      $util->printDebug( "reaped child $pid" );
    }
    @{$self->{'pids'}} = (); # clear the PIDs array
    $util->printDebug( "no more children" );
  }

  if( $uploadInfo->{'multiPartID'} )
  {
    # This is empty (we won't enter here) if no multipart upload in progress
    # We are in here so abort the upload
    my @query    = $target->getAbortMultipartUpload( $target->{'name'}, $uploadInfo->{'multiPartID'} );
    my @response = $target->{'curl'}->curl( @query );
    (my $httpCode, my $httpMsg) = $util->httpCodeCheck("204", @response);
    if( not $httpCode )
    {
      $util->printDebug( "S3 multipart upload abort failed: $httpMsg" );
    }
    $util->printDebug( "aborted multipart upload $uploadInfo->{'multiPartID'}" );
  }
  if( !$keepFile )
  {
    # Remove the temporary directory and all its files
    foreach my $file (@{$uploadInfo->{'fileList'}})
    {
      unlink($file);
      $util->printDebug( "removed $file from upload tmpdir" );
    }
    rmdir($uploadInfo->{'workingDir'});
  }
  $util->printDebug( "done cleaning up from upload $uploadInfo->{'id'}" );
}

sub reapChild
{
  # Removed the given child's PID from the list
  my $self          = shift;
  my $child         = shift;
  my $inRC          = shift;
  my $uploadInfo    = $self->{'uploadInfo'};
  my $error         = 0x0;
  my $partInfoRef;

  foreach my $partRef (@{$uploadInfo->{'partsList'}})
  {
    if( defined $partRef->{'pid'} && $partRef->{'pid'} == $child )
    {
      $partInfoRef = $partRef;
      last;
    }
  }

  if( not $partInfoRef )
  {
    croak "couldn't find part info for " . $child;
  }

  # Get the feedback
  my $readerFH    = $partInfoRef->{'rFeedback'};
  my $receivedMsg = <$readerFH>;
  close $readerFH;
  if( $receivedMsg )
  {
    chomp $receivedMsg;
    $util->printDebug( "received feedback \"" . $receivedMsg . "\" from $child" );
    if( $s3 )
    {
      # Get the ETag from the pipe
      if( $receivedMsg =~ m/^ETag=(.+)$/ )
      {
        my $etag = $1;
        $partInfoRef->{'etag'} = $etag;
      }
      else { $error |= 0x0001; }
    }
    else
    {
      # Get the OK message from the pipe
      if( not ($receivedMsg eq $childOkMsg) ) { $error |= 0x0002; }
    }
  }
  else { $error |= 0x0004; }

  # Get the upload size
  $readerFH     = $partInfoRef->{'rUploadSize'};
  $receivedMsg  = <$readerFH>;
  close $readerFH;
  if( $receivedMsg )
  {
    chomp $receivedMsg;
    $util->printDebug( "received upload size \"" . $receivedMsg . "\" from $child" );
    if( not $receivedMsg =~ m/\d+/ )
    {
      $error |= 0x0008;
    }
    $partInfoRef->{'uploadSize'}  = $receivedMsg;
    # Add the number of bytes uploaded
    $uploadInfo->{'uploaded'} += $partInfoRef->{'uploadSize'};

  }
  else { $error |= 0x0010; }

  if( $error )
  {
    my $errorMsg = &checkChildRC( $inRC, $child, $error );
    return( "Upload part child failed to return upload confirmation.\n" .
            "Error message: " . $errorMsg );
  }

  my $pidList = join(" ", @{$self->{'pids'}});
  $pidList = "($pidList)";
  $util->printDebug( "about to reap child $child from $pidList" );

  for( my $i = 0; $i < $maxThreads; $i++ )
  {
    if( $child == $self->{'pids'}[$i] )
    {
      # Remove the pid from the pids array
      splice( @{$self->{'pids'}}, $i, 1 );

      # Remove the unneeded information from the parts list
      delete $partInfoRef->{'pid'};
      delete $partInfoRef->{'uploadSize'};
      delete $partInfoRef->{'rFeedbackSize'};
      delete $partInfoRef->{'rFeedback'};
      delete $partInfoRef->{'rUploadSize'};
      if( $DEBUG )
      {
        my $remChildren = ($#{$self->{'pids'}}+1);
        $util->printDebug( "reaped child $child, $remChildren children still running" );
      }
      return;
    }
  }
  croak "child $child not found in pids list $pidList";
}

sub checkChildRC
{
  # Check RC from child process and return any errors

  my $rc    = shift;
  my $pid   = shift;
  my $error = shift;

  if(    $rc == MoveToCloud::Constants::CHILD_ERR_NO     ) { return "" }
  elsif( $rc == MoveToCloud::Constants::CHILD_ERR_GZIP   ) { return "Compression with GZip failed" }
  elsif( $rc == MoveToCloud::Constants::CHILD_ERR_UPLOAD ) { return "Upload failed" }
  elsif( $rc == MoveToCloud::Constants::CHILD_ERR_INT    ) { return "Interrupted" }
  else
  {
    croak "unrecognized RC \"$rc\" (error code $error) from child $pid";
  }
}

sub stat
{
   my $fileToUpload = shift;
   return ( (stat($fileToUpload))[7] );
}

package MoveToCloud::SoftlayerUploadTask;
@MoveToCloud::SoftlayerUploadTask::ISA = qw(MoveToCloud::UploadTask); # Softlayer inherits from UploadTask

use 5.010;
use strict;
use warnings;
use Carp;

sub new
{
  my $class = shift;
  my $self  = $class->SUPER::new(shift, shift, shift, shift); # inherit all fields from parent 

  bless $self, $class;
  return $self;
}

sub putFile
{
  my $self         = shift;
  my $pipes_ref    = shift; 
  my $fileToUpload = shift;
  my $part_ref     = shift; 
  my $target       = $self->{'target'};
  my $errorMsg     = $self->{'errorMsg'};

  $part_ref->{'target'} = $target->{'parts_prefix'}.$part_ref->{'id'};
  $util->printDebug( "uploading $fileToUpload to $part_ref->{'target'}" );
  if( $errorMsg = $target->putFile( $fileToUpload, $part_ref->{'target'}) )
  {
     # Upload failed
     if( !$keepFile )
     {
        # We only want to keep the file around if debugging
        unlink( $fileToUpload );
     }
     close $pipes_ref->{'wFeedback'};
     exit MoveToCloud::Constants::CHILD_ERR_UPLOAD;
  }
  print {$pipes_ref->{'wFeedback'}} $childOkMsg;
}

sub completeMultipartUpload
{
  my $self               = shift;
  my $uploadCompleteFile = "$self->{'uploadInfo'}{'workingDir'}/uploadComplete";
  my $errorMsg           = $self->{'errorMsg'};
  my $target             = $self->{'target'};

  # Create the manifest file at the actual target location
  $util->openFile( 'uploadComplete', '>', $uploadCompleteFile );
  print {$self->{'filehandles'}{'uploadComplete'}} "";
  $util->closeFile( 'uploadComplete' );
  if( $errorMsg = $target->putFile( $uploadCompleteFile, $target->{'name'},
                                    "-H \"X-Object-Manifest: $target->{'container'}/$target->{'parts_prefix'}\"" ) )
  {
     unlink( $$uploadCompleteFile );
     $self->cleanupUpload( $errorMsg );
     return __LINE__;
  }
  return $errorMsg;
}

package MoveToCloud::S3UploadTask;
@MoveToCloud::S3UploadTask::ISA = qw(MoveToCloud::UploadTask); # S3 inherits from UploadTask

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Carp;

sub new
{
  my $class = shift;
  my $self  = $class->SUPER::new(shift, shift, shift, shift); # inherit all fields from parent 

  bless $self, $class;
  return $self;
}

sub setup
{
  my $self = shift;
  $self->SUPER::setup(shift);           
  $self->initiateMultipartUpload();
}

sub initiateMultipartUpload
{
  # Initiate multipart upload
  my $self       = shift;
  my $target     = $self->{'target'};
  my $uploadInfo = $self->{'uploadInfo'};
  my @query      = $target->getInitMultipartUpload( $target->{'name'} );
  my @response   = $target->{'curl'}->curl( @query );
  (my $httpCode, my $httpMsg) = $util->httpCodeCheck("200", @response);
  if( not $httpCode )
  {
     $self->{'errorMsg'} = "S3 multipart upload initialization failed: $httpMsg";
     $self->cleanupUpload( $self->{'$errorMsg'} );
     return __LINE__;
  }
  # Last line should contain the upload ID
  $response[$#response] =~ /UploadId>(.*)<\/UploadId/;
  $uploadInfo->{'multiPartID'} = $1;
  if( not $uploadInfo->{'multiPartID'} )
  {
     croak "failed to get multiPartID";
  }
  $util->printDebug( "initiated multipart upload $uploadInfo->{'multiPartID'}" );
}

sub putFile
{
  my $self         = shift;
  my $pipes_ref    = shift;
  my $fileToUpload = shift;

  my $uploadInfo = $self->{'uploadInfo'};
  my $target     = $self->{'target'};
  my $inputs     = $self->{'inputs'};

  my @query = $target->getPutPart( $target->{'name'},
                                   $uploadInfo->{'multiPartID'},
                                   $fileToUpload,
                                   $uploadInfo->{'partCount'}   );
  my $attempt = 0;
  my $success = 0;
  my @response;
  while( $attempt < MoveToCloud::Constants::MAX_PUT_ATTEMPTS )
  {
     @response = $target->{'curl'}->curl( @query );

     # Put request will return Continue first, then a blank line, then the
     # message we are interested in
     (my $httpCode, my $httpMsg) = $util->httpCodeCheck("200", @response);
     if( not $httpCode )
     {
        $attempt++;
        sleep MoveToCloud::Constants::ATTEMPT_SLEEP;
        next;
     }
     $success = 1;
     last;
  }

  if( not $success )
  {
     # Upload failed
     if( !$keepFile )
     {
        # We only want to keep the file around if debugging
        unlink( $fileToUpload );
        unlink( $inputs->{'curlout'}.$curlStmt );
        unlink( $inputs->{'curlout'} );
     }
     close $pipes_ref->{'wFeedback'};
     exit MoveToCloud::Constants::CHILD_ERR_UPLOAD;
  }

  # Save the ETag from the response
  my @etags = grep( /ETag: /, @response );
  $etags[$#etags] =~ /ETag: "(.*)"/;
  my $etag = $1;
  $util->printDebug( "ETag = $etag" );

  # Send the ETag back to the parent
  print {$pipes_ref->{'wFeedback'}} "ETag=" . $etag;
}

sub completeMultipartUpload
{
  my $self               = shift;
  my $target             = $self->{'target'};
  my $uploadInfo         = $self->{'uploadInfo'};
  my $uploadCompleteFile = "$uploadInfo->{'workingDir'}/uploadComplete";

  # Complete the multipart upload
  my $attempt = 0;
  my $success = 0;
  my $httpMsg;
  while( $attempt < MoveToCloud::Constants::MAX_PUT_ATTEMPTS )
  {
    my @query     = $target->getCompleteMultipartUpload( $target->{'name'},
                                                         $uploadInfo->{'multiPartID'},
                                                         $uploadCompleteFile,
                                                         @{$uploadInfo->{'partsList'}} );
    my @response  = $target->{'curl'}->curl( @query );
    (my $httpCode, $httpMsg) = $util->httpCodeCheck("200", @response);
    if( not $httpCode )
    {
      $attempt++;
      sleep MoveToCloud::Constants::ATTEMPT_SLEEP;
      next;
    }
     $success = 1;
     last;
  }
  if( not $success )
  {
    # Upload failed
    if( !$keepFile )
    {
      # We only want to keep the file around if debugging
      unlink( $uploadCompleteFile );
    }
    $self->cleanupUpload( "Complete multipart upload to \"$target->{'name'} failed: $httpMsg" );
    return __LINE__;
  }
  $uploadInfo->{'multiPartID'} = "";
}

package MoveToCloud;
use 5.010;
use strict;
use warnings;

use Carp;
use sigtrap qw(handler signal_handler normal-signals stack-trace error-signals);
use Encode qw(encode_utf8);
use Cwd;
use Digest::MD5;
use File::Basename;
use Data::Dumper;

sub main;
#sub sigtrap;

$SIG{INT}  = \&MoveToCloud::Util::sigtrap;
$SIG{TERM} = \&MoveToCloud::Util::sigtrap;

my @prerequisites = ( 'curl', 'gzip' );

################################################################################
################################################################################
#
# CALL MAIN
main();
#
################################################################################
################################################################################

################################################################################
################################################################################
#
# SUBROUTINES
#
################################################################################
################################################################################

sub checkPrereqs
{
  # Check the necessary system commands are installed/available

  foreach my $prereq (@prerequisites)
  {
    next if( (not $compress) and ($prereq eq 'gzip') );

    `which $prereq 2>&1`;
    if( $? != 0 )
    {
      `where $prereq 2>&1`;
      if( $? != 0 )
      {
        die "$prereq not found. Install $prereq and make sure it is in the system path.";
      }
    }
  }
}

sub configure
{
  my $inputs = shift;
  $inputs->parseInputs();
  &checkPrereqs;
  $inputs->checkSource();
  &MoveToCloud::Target::checkTarget($inputs);
}

sub main
{
  my $rc = 0;
  
  my $inputs = MoveToCloud::Inputs->new();
  $util->setInputs($inputs);
  &configure($inputs);

  if( $mode eq 'single' )
  {
    my $uploadTask;

    if ( $softlayer )
    {
      $uploadTask = MoveToCloud::SoftlayerUploadTask->new($inputs, $target, \%filehandles );
    }
    elsif ( $s3 )
    {
      $uploadTask = MoveToCloud::S3UploadTask->new($inputs, $target, \%filehandles );
    }

    $rc = $uploadTask->uploadSourceToTarget(1);
  }

  elsif( $mode eq 'batch' )
  {
    my $uploadCount = 0; # used as ID of upload task
    my @uploadsList = @{$inputs->{'uploads'}};
    my $uploadTask;

    if ( $softlayer )
    {
      $uploadTask = MoveToCloud::SoftlayerUploadTask->new($inputs, $target, \%filehandles );
    }
    elsif ( $s3 )
    {
      $uploadTask = MoveToCloud::S3UploadTask->new($inputs, $target, \%filehandles );
    }
    foreach my $upload_ref ( @uploadsList )
    {
      next if( defined $upload_ref->{'skip'} );
      $uploadCount++;
      $upload_ref->useThisUpload( $target, $inputs );
      $rc = $uploadTask->uploadSourceToTarget($uploadCount);
      $util->printDebug( "Upload $uploadCount rc = $rc" );
      if( $rc )
      {
        # Check if we can skip
        if( $errorexit == -1 )
        {
          # errorexit option not set, prompt user
          if( not $util->askBool( "Upload $uploadCount failed.\nSkip this upload?", $inputs ) )
          {
            $util->userError( "Upload $uploadCount failed. Skip disabled. Exiting." );
          }
        }
        if( $errorexit == 1 )
        {
          # errorexit set or user chose exit, so exit
          $util->userError( "Upload $uploadCount failed. Exiting." );
        }

        # Else just skip
        $util->printWarn( "Skipping upload #$upload_ref->{'id'}" );
        $uploadCount--;
      }
    }
    $util->printOut( "Completed $uploadCount uploads successfully (out of " . (1+$#uploadsList) . ")." );
  }

  elsif( $mode eq 'delete' )
  {
    $rc = $target->deleteTarget( $scriptID, $inputs );
  }

  $util->cleanup();
  exit 0;
}

################################################################################

=head1 NAME

moveToCloud.pl - Upload file(s) to cloud storage.

=cut

=head1 DESCRIPTION

Uploads file(s) to (or delete from) cloud storage.
This script can handle large files and is multi-threaded to improve speed.
The source file is split into chunks which are compressed with gzip (unless '-nocompression' set) then uploaded via cURL to the target.

=cut

=head1 SYNOPSIS 

moveToCloud.pl -source <source> -target <target> [options]

moveToCloud.pl -batch <batch> [options]

moveToCloud.pl -test -target <test> [options]

moveToCloud.pl -delete -target <delete> [options]

moveToCloud.pl -list

moveToCloud.pl [-help | -man]

options = [-creds <credentials>] [-token] [-threads <threads>] [-nocompression] [-tmpdir <temp_directory>] [-verbose [<output_file>]] [-quiet] [-yes | -no]

Where: 

  source      = data file to upload (absolute or relative path) 

  target      = where to store the file in the cloud
                format: <service>::<url>::<container>::<path>

  batch       = batch file describing a list of uploads

  test        = target information to test the cloud account information
                format: <service>::<url>::<container>::<path>

  delete      = target file (or directory) to delete from storage
                format: <service>::<url>::<container>::<path>

=cut

=head1 USAGE_DETAILS

=over 4

=item C<-source>

Source file path.

=item C<-target>

Target path. See TARGET_DETAILS.

=item C<-batch>

Batch file path. See BATCH_FILE_DETAILS.

=item C<-test>

Test target details. See TEST_DETAILS.

=item C<-delete>

Delete target details. See DELETE_DETAILS.

=item C<-creds>

Credentials file path. See CREDENTIALS_DETAILS.

=item C<-threads>

Maximum number of concurrent threads used. Default is 5.

=item C<-nocompression>

Disable compression. Default behaviour is to compress files with gzip.

=item C<-token>

Use SoftLayer token authentication. See TOKEN_DETAILS.

=item C<-tmpdir>

Temporary work area directory. All temporary files created by the script will be stored in this directory and will be deleted after use.

=item C<-list>

Lists supported services and URL endpoints. See URL_DETAILS.

=item C<-verbose>

Be verbose about progress. Optional value for output file to print to instead of STDOUT.

=item C<-quiet>

Print no messages to STDOUT while running.

=item C<-yes>

Automatically respond "yes" to all prompts that are displayed during processing.

=item C<-no>

Automatically respond "no" to all prompts that are displayed during processing.

=item C<-help>

Brief help message.

=item C<-man>

Manual page for script.

=back

=cut

=head2 TARGET_DETAILS

=over 4

=item Format

<service>::<url>::<container>::<path>

Where:

  service    = one of the supported services *
  url        = either a service tag or full url *
  container  = the container/bucket name to use
  path       = file path in cloud storage **

=item Example

SoftLayer::Dallas::mycontainer::/put/file/here/datafilecopy

=item Notes

* See '--list' for service and url information.
  If you use a non-SSL connection, you will be prompted to verify that SSL will not be used.
  If you use a Softlayer token, url refers to the X-Storage-Url.

** If this ends with a '/' then the original name is used under that path, else the file is renamed. If -nocompression is NOT specified, the file name will always be appended with .gz

=back

=cut

=head2 BATCH_FILE_DETAILS

This package came with a sample batch file "sample_batch.txt". See the sample for a full description of how set up a batch file.

=cut

=head2 TEST_DETAILS

The test mode should be used before uploading to an account for the first time. It will verify the credentials, URL and container specified. If a path is also specified, it will check no file(s) exist with that name.

=cut

=head2 DELETE_DETAILS

Deletes the target file or directory from cloud storage. If the input value ends in a '/' it attempts to delete a directory. Deleting a directory deletes all files recursively under the path. In SoftLayer, if the target is a large object (manifest file), the associated parts are also deleted.

Prompts the user for confirmation unless the -quiet or -yes option is used.

=cut

=head2 CREDENTIALS_DETAILS

This package came with a sample credentials file "sample_credentials.txt". See the sample for a full description of how set up a credentials file.
If you do not specify a credentials file, you will be prompted to supply the following user credentials:

Amazon S3:

=over 4

=item * 

access key ID

=item * 

secret access key

=back

SoftLayer:

=over 4

=item * 

username

=item * 

password

=back

=cut

=head2 TOKEN_DETAILS

SoftLayer token authentication can be used with credentials option. See the sample credentials file "sample_credentials.txt" for a full description of how set up a credentials file using a token. 
If you do not specify a credentials file, you will be prompted to enter your token.

=cut

=head1 RESULT

Upon successful completion the file will be available at the specified target. If compression was not disabled then the file name will be appended with '.gz'.

For example without the -nocompression flag a target name of "myfile" will appear as "myfile.gz".

In SoftLayer a subfolder will be created in the target's directory, with the file name plus the suffix ".parts". This directory contains the parts of the file with the suffix "_XXX" where XXX is the part number. The target is actually a manifest file, and when this is downloaded the parts are sent in order.

  0   = success
  1   = input error
  2   = interrupted
  n   = line of code at failure

=cut

=head1 AUTHOR

(C) Copyright IBM Corp. 2014, 2015

=cut

