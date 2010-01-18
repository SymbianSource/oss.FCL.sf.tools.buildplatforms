#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
#
#-------------------------------------------------------------------------------
# package: SysDefParser
#
# usage: Wrapper for an XML parser to dispatch callbacks to a client object which
#    analyses the parsed XML data. The auxiliary package SysDefParser::Dispatcher
#    acts as an intermediary between the parser and the client to convert function
#    callbacks to method callbacks using perl's AUTOLOAD mechanism.
#
# public methods:
#
#    new(-client => <client reference>, [-parser => <package name>]) : creates a
#        instance. <client reference> is the instance to which the parser callbacks
#        are dispatched. <package name> is an optional alternative parser client
#        package to use instead of the default XML::Parser class.
#
#    parse(<fileh>): parse the XML data from filehandle <fileh> dispatching
#        callbacks to the client object.
#         
#-------------------------------------------------------------------------------

package SysDefParser;
use strict;

sub new
{
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{client} = delete $args{-client};

    if (exists $args{-parser})
    {
        $args{Pkg} = 'SysDefParser::Dispatcher';
        require $args{-parser};
        $self->{parser} = $args{-parser}->createParser(%args);
    }
    else
    {
        $self->{parser} = $class->_createParser(%args);
    }

    return $self;
}

sub _createParser
{
    my ($class, %args) = @_;
    require XML::Parser;
    return XML::Parser->new
           (
               Style        => 'Subs',
               Pkg          => 'SysDefParser::Dispatcher',
               ErrorContext => 2
           );
}

my $PARSERCLIENT = undef;

sub _client { return $PARSERCLIENT; }

sub parse
{
    my ($self, $fileh) = @_;

    # we can't pass any context down to the underlying parser so that we can work out which
    # object any callbacks from the parser are associated with so, assuming that the parser will
    # not be called in a re-entrant fashion, we store the context at this point, so that we can
    # then dispatch the callbacks from the parsers 'parse' method to those methods of the saved
    # $PARSERCLIENT instance.

    die "Fatal: client object not set\n" if ! defined $self->{client};
    die "Fatal: parser client object already set\n" if defined $PARSERCLIENT;
    $PARSERCLIENT = $self->{client};

    # call the parser, callbacks will be dispatched to sub AUTOLOAD in SysDefParser::Dispatcher

    my $rv =$self->{parser}->parse($fileh);

    # finished parsing, unset the context

    $PARSERCLIENT = undef;

    return $rv;
}

#-------------------------------------------------------------------------------
# package SysDefParser::Dispatcher
#
# usage: Internal package. Uses AUTOLOAD mechanism to receive parser callbacks and
#    convert them to object method calls on teh client object.
#
#-------------------------------------------------------------------------------
package SysDefParser::Dispatcher;
use strict;

sub AUTOLOAD
{
    my @ARGS = @_;

    my $client = SysDefParser::_client();

    die "Fatal: parser client object not set\n" if ! defined $client;

    # translate the called back function name to the client method name
    my $clientpkg = ref($client);
    my $method = $SysDefParser::Dispatcher::AUTOLOAD;

    $method =~ s/^SysDefParser::Dispatcher/$clientpkg/;

    # dispatch the parser's callback to the client object (if implemented by client)
    $client->$method(@ARGS) if $client->can($method);
}

#-------------------------------------------------------------------------------
# -EOF-
#-------------------------------------------------------------------------------
1;