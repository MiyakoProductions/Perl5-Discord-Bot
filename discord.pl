#!/usr/bin/perl -w
use experimental 'smartmatch';
use strict;
use JSON qw( decode_json );
use JSON qw( encode_json );
use WWW::Mechanize;
use Data::Dumper;

# Prototype global variables
our $baseUrl = "https://www.discordapp.com/api/";
our $email = "place\@holder.com";
our $password = "placeholder";
our $lastMsgID = "0";

# Clear the terminal screen
BEGIN { system "clear"; }

# This function logs into a normal user account
# login( str email, str password );
# example: login( "example\@email.com", "password" );
# returns a string $authToken used in most calls
sub login( $$ ) {
	# Set local variables
	my $apiEmail = $_[0];
	my $apiPassword = $_[1];
	my $apiUrl = $baseUrl . "auth/login";
	my $postData = encode_json { "email" => $apiEmail, "password" => $apiPassword };

	# Connect to Discord
	my $discordClient = WWW::Mechanize->new( agent => 'DiscordBot ( LibDiscord-Perl5 1 )' );
	my $clientConnected = eval { $discordClient->post( $apiUrl, 'Content-Type' => 'application/json', Content => $postData ); };
	if ( ! $clientConnected ) { errorCon( ); } # Error on any connection errors
	else { # Set values when connection is successful
		our $apiContent = $discordClient->content;
		our $apiJson = decode_json( $apiContent );
		our $apiToken = $apiJson->{'token'};
		return ( $apiToken ); # Return Auth Token
	}
}
our $authToken = login( $email, $password );

sub logout {
# logout of auth token	
}

# Gets the info of a desired channel id
# getChannel( str channelid );
# example: getChannel( 193239098226376705 );
sub getChannel( $ ) {
	my $apiUrl = $baseUrl . "channels/" . $_[0];
	my $discordClient = WWW::Mechanize->new( agent => 'DiscordBot ( LibDiscord-Perl5 1 )' );
	$discordClient->add_header( 'Authorization' => "$authToken" );
	$discordClient->get( $apiUrl, 'Content-Type' => 'application/json' );
	my $clientConnected = eval { $discordClient->get( $apiUrl, 'Content-Type' => 'application/json' ); };
	if ( ! $clientConnected ) { errorCon( ); }
	else { # Set values when connection is successful
		our $apiContent = $discordClient->content;
		our $apiJson = decode_json( $apiContent );
		print "Pretty Response:\n" . Dumper( $apiJson ) . "\n";
	}
}

# Retreive messages from Discord
# getMessages( str channelid );
# example getMessages( 193239098226376705 );
sub getMessages( $ ) {
	my $apiUrl = $baseUrl . "channels/" . $_[0] . "/messages?limit=1";
	my $discordClient = WWW::Mechanize->new( agent => 'DiscordBot ( LibDiscord-Perl5 1 )' );
	# Add the auth token to the header
	$discordClient->add_header( 'Authorization' => "$authToken" );
	my $clientConnected = eval { $discordClient->get( $apiUrl, 'Content-Type' => 'application/json' ); };
	if ( ! $clientConnected ) { errorCon( ); }
	else { # Set values when connection is successful
		our $apiContent = $discordClient->content;
		# Decod json to a local variable
		my $apiJson = decode_json( $apiContent );
		# Deserialize variables for use
		my $msgID = $apiJson->[0]->{'id'}; # Message ID
		my $msgAuthor = $apiJson->[0]->{'author'}->{'username'}; # Username that posted
		my $msgContent = $apiJson->[0]->{'content'}; # Contents of the message
		
		if ( $msgID > $lastMsgID ) { # Make sure not to get the same message twice in a row
			our @message = split( " ", $msgContent ); # Split message contents into an array for use with bot functions
			print "msgId: $msgID <$msgAuthor> @message\n"; # Debug print to see if it is working.
			
			# Begin adding commands, this will later be a sperate file that is called
			
			# Simple test command
			if ( $message[0] eq "!test" ) { 
				createMessage( 193239098226376705, "Success!" );
			}
			
			# ShadowRun Dice Roller
			if ( $message[0] eq "!roll" ){
				if ( $message[1] eq "inf" ) { # Prevent the calling of infinity dice
					createMessage( 193239098226376705, "Infinity is not a valid roll. Please roll again." );
				}
				# Set a maximum dice limit to avoid spamming a channel
				if ( $message[1] > 10 ) { createMessage( 193239098226376705,"Maximum is 10 dice." );}
				# Roll the dice
				else {
					# Set local variables
					my $hit = "0";
					my $hitcount = 0;
					my $glitchcount = 0;
					# Loop for the number of dice requested
					for ( my $i = 0; $i < $message[1]; $i++ ) {
						my $lower=1; # Minimum value
						my $upper=6; # Maximum value
						# Randomly generate a number
						my $random = int( rand( $upper-$lower+1 ) ) + $lower;
						if ( $random == 5 || $random ==6 ) { $hit = "Hit!"; $hitcount++; } # Player scored a hit
						elsif ( $random == 1 ) { $hit = "Glitch!"; $glitchcount++;} # Player glitched
						elsif ( "-h" ~~ @message ) { # Accept an argument for when players have a harder roll
							if( $random == 2 ) { $hit = "Glitch!"; $glitchcount++; }
						} 
						else { $hit = "0"; } # Player didn't hit
						if ( "-v" ~~ @message ) { # Verbose Output
							createMessage( 193239098226376705, "$msgAuthor rolls: $random $hit" );
						}
					}
					if ( "-q" ~~ @message ) { # Be quiet and only show the total without the player
						createMessage( 193239098226376705, "Hits: $hitcount Glitches: $glitchcount" );
					}
					else { # Show the total with the player that rolled
						createMessage( 193239098226376705, "$msgAuthor Hits: $hitcount Glitches: $glitchcount" );
					}
					if ( $hitcount == $message[1] ) { # Every roll was a hit, thus critical success
						createMessage( 193239098226376705, "CRITICAL SUCCESS!!!" );
					}
					if ( $glitchcount >= 1 && $hitcount == 0 ) { # Every roll was a glitch, thus critical failure
						createMessage( 193239098226376705, "CRITICAL FAIL!!!" );
					}				
				}
			}
			$lastMsgID = $msgID; # Make sure not to get the same message twice in a row
		}
	}
}

# Send a message to a channle
# createMessage( str channelid, str contents );
# example: createMessage( 193239098226376705, "test message" );
sub createMessage( $$ ) {
	my $apiUrl = $baseUrl . "channels/" . $_[0] . "/messages";
	my $postData = encode_json { "content" => "$_[1]" };
	print Dumper( $postData ) . "\n";
	my $discordClient = WWW::Mechanize->new( agent => 'DiscordBot ( LibDiscord-Perl5 1 )' );
	$discordClient->add_header( 'Authorization' => "$authToken" );
	#$discordClient->add_header( 'Authorization' => '' );
	$discordClient->post( $apiUrl, 'Content-Type' => 'application/json', Content => "$postData" );
	# Debug response message
	#my $clientConnected = eval {$discordClient->post( $apiUrl, 'Content-Type' => 'application/json', Content => "$postData" ); };
	#if ( ! $clientConnected ) { errorCon( ); }
	#else { # Set values when connection is successful
	#	our $apiContent = $discordClient->content;
	#	#print Dumper( $apiContent ) . "\n";
	#	# print "Actual Response:\n" . Dumper( $apiContent ) . "\n";
	#	our $apiJson = decode_json( $apiContent );
	#	#print "Pretty Response:\n" . Dumper( $apiJson ) . "\n";
	#}
}

# Handle connection errors
sub errorCon {
	print "Error: Unable to connect to Discord!\n";
}

# Loop a single thread, future version will be multi-threaded
while ( 1 ) {
	getMessages( 193239098226376705 );
	sleep 1; # Discord has a rate limit, so comply with it.
}
