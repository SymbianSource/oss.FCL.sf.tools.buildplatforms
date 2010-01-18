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
# package: SysDefCollector
#
# usage: Interacts with the SysDefParser to obtain those parts of the system
#        definition which are relevant to building a named configuration within the
#        system definition. Contains a SysDefCollector::ParserClient instance which
#        acts as the interface to the SysDefParser. This separation reduces the
#        possibility of a method name clash due to the parser callback mechanism
#        requiring the client to implement methods of the same name as the XML
#        element tags of interest.
#
# public methods:
#
#    new(configname, loghandle): constructs a new instance to collect system 
#       definition info relating to the configuration name 'configname'.
#
#    parserClient(): returns a reference to the SysDefCollector::ParserClient
#       instance - typically for passing to the parser.
#
#    options(): returns a list of the abld options flags as specified in the
#       'option' elements.
#
#    targets(): returns a list of the abld target flags as specified by the
#       'targetList' attributes for each 'buildLayer' element in the specified
#       configuration.
#
#    specialInstructionsFlag(): returns true/false accordingly as any relevant
#       'specialInstructions' elements are present/not present. Relevant means
#       instructions which invoke SETUPPRJ.BAT.
#
#    components(): returns a hash of component name and bldFile directories
#        for each component to be built for the specified configuration.
#
#    dump(): debug/development method to dump the internal data structures
#
#    test(): debug/development method to dump the results of the methods
#        'options()', 'targets()', 'specialInstructionsFlag()', 'components()'.
#
#-------------------------------------------------------------------------------
package SysDefCollector;
use strict;

my $debugFlag = 0;

sub new 
{
    my ($class, $configname, $loghandle) = @_;
    my $self = { client => SysDefCollector::ParserClient->new($configname,$loghandle), loghandle => $loghandle };
    return bless $self, $class;
}

sub parserClient
{
    my $self = shift;
    return $self->{client};
}

#-------------------------------------------------------------------------------
# sub options() - returns the translated list of options for each 'option' element
#-------------------------------------------------------------------------------
sub options
{
    my $self = shift;
    return $self->_collectedList('option');
}

#-------------------------------------------------------------------------------
# sub targets() - returns the translated list of targets for each 'buildLayer'
#    in the named configuration.
#-------------------------------------------------------------------------------
sub targets
{
    my $self = shift;

    my @targets;
    my @buildLayerTargetList = $self->_collectedList('buildLayerTargetList');

    for my $layerTarget (@buildLayerTargetList)
    {
        my %targetListHash = $self->_collectedHash('targetList');
        my @targetList = @{ $targetListHash{$layerTarget} };
        push @targets, @targetList;
    }

    # eliminate any duplicates by storing as hash keys
    my %targetHash = map { $_, '' } @targets;

    # now translate via the target mapping
    my %targetMap = $self->_collectedHash('target');
    @targets = map { $targetMap{$_} } keys %targetHash;

    return @targets;
}

#-------------------------------------------------------------------------------
# sub specialInstructionsFlag() - returns true if 'specialInstructions' elements are present.
#-------------------------------------------------------------------------------
sub specialInstructionsFlag
{
    my $self = shift;
    my $flag = 0;
    $flag = $self->_collected()->{specialInstructions}
                        if exists $self->_collected()->{specialInstructions};
    return $flag;
}

#-------------------------------------------------------------------------------
# sub components() - returns an array of components to be built for the named
#    configuration. Each array element is a reference to a further array whose
#    element[0] is the component name and element[1] is the directory location
#    of that component's 'bld.inf' file.
#-------------------------------------------------------------------------------
sub components
{
    my $self = shift;
    my $loghandle = $self->{loghandle};
    
    my @unitNames;
    my @unitListRef = $self->_collectedList('unitListRef');
    my %unitList    = $self->_collectedHash('unitList');
    my %unitListNamesHash;  # Used to detect duplicates and then discarded!
    my %unitNamesHash;      # Used to detect duplicates and then discarded!
    my %unitMap = $self->_collectedHash('unit');
    
    for my $unitListName (@unitListRef)
    {
        if (defined $unitListNamesHash{$unitListName})
        {    # Duplicate unitListName! Ignore it!
            print $loghandle "Ignoring duplicated unitList: $unitListName\n";
            next;
        }
        $unitListNamesHash{$unitListName} = 1;
        unless (defined $unitList{$unitListName})
        {     # No info for this unitList!
            print $loghandle "No Unit info for unitList: $unitListName\n";
            next;
        }
        my @units = @{ $unitList{$unitListName} };
        foreach my $unit (@units)
        {
            if (defined $unitNamesHash{$unit})
            {    # Duplicate unit name! Ignore it!
                print $loghandle "Ignoring duplicated Unit: $unit\n";
                next;
            }
            $unitNamesHash{$unit} = 1;
            unless (defined $unitMap{$unit})
            {      # No bldFile (directory) info for this component!
                print $loghandle "No bldFile info for Unit: $unit\n";
                next;
            }
            my @unitdef = ($unit, $unitMap{$unit});
            push @unitNames, \@unitdef;
        }
    }

    return @unitNames;
}

#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
sub dump
{
    my $self = shift;
    my $fh = shift;
    $self->parserClient($fh)->dump($fh);
}

#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
sub test
{
    my $self = shift;
    my $fh = $self->{loghandle};    # Logfile handle

    my @options    = $self->options();
    my @targets    = $self->targets();
    my $special    = $self->specialInstructionsFlag();
    my @components = $self->components($fh);

    print $fh "\nTest Collected System Definition Query Methods\n";
    print $fh "==============================================\n";

    print $fh "options: ['", (join "', '", @options), "']\n";
    print $fh "targets: ['", (join "', '", @targets), "']\n";
    print $fh "special instructions: '", ($special ? "yes" : "no" ), "'\n";
    print $fh "components:\n{\n";
    for my $component (@components)
    {
        print $fh "\t'", $component->[0], "' => '", $component->[1], "'\n";
    }
    print $fh "}\n";
    print $fh "==============================================\n";
}

#-------------------------------------------------------------------------------
# private methods:
#-------------------------------------------------------------------------------
sub _collected
{
    my $self = shift;
    return $self->parserClient()->{collected};
}

sub _collectedHash
{
    my ($self, $slot) = @_;
    my %hash = ();
    %hash = %{ $self->_collected()->{$slot} }
                        if exists $self->_collected()->{$slot};
    return %hash;
}

sub _collectedList
{
    my ($self, $slot) = @_;
    my @list = ();
    @list = @{ $self->_collected()->{$slot} }
                        if exists $self->_collected()->{$slot};
    return @list;
}

#-------------------------------------------------------------------------------
# package: SysDefCollector::ParserClient
#
# usage: Interacts directly with the SysDefParser to obtain those parts of the system
#        definition which are of interest. Implements the parser callback methods
#        for the XML elements for which we collect information. Some elements are
#        of interest only if they are enclosed within an outer element with certain
#        properties. Other elements are always of interest. The latter style of
#        element is always collected. The former is only collected when it is known
#        that we are within an appropriate enclosing element. The 'context' property
#        is used for testing this condition.
#
# methods:
#
#    new(configname): constructs a new instance to collect system definition info
#       relating to the configuration name 'configname'.
#
#    parserClient(): returns a reference to the SysDefCollector::ParserClient
#       instance - typically for passing to the parser.
#
#-------------------------------------------------------------------------------
package SysDefCollector::ParserClient;
use strict;

sub new
{
    my ($class, $configname, $loghandle) = @_;
    my $self = { configname => $configname, configfound => 0, context => {intask => 0}, collected => {}, loghandle => $loghandle };
    return bless $self, $class;
}

#-------------------------------------------------------------------------------
# The following methods 'configuration()', 'configuration_()' initiate and
# terminate respectively the collection of element information found inside a
# 'configuration' element with 'name' attribute matching the objects 'configname'
# attribute.
#-------------------------------------------------------------------------------
sub configuration
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);
    my $loghandle = $self->{loghandle};

    # start of a 'configuration' element - if the name of the element matches our
    # 'configname' attribute then we create contexts so that elements of interest
    # nested within this 'configuration' element can be collected.
    unless ($attrs{name} eq $self->{configname}) { return; }
    
    if ($self->{configfound})
    {
        print $loghandle "Ignoring duplicated configuration: $attrs{name} ($attrs{description})\n";
    }
    else
    {
        $self->{configfound} = 1;
        $self->{context}->{unitListRef} = [];
        $self->{context}->{buildLayerTargetList} = [];
    }
}

sub configuration_
{
    my ($self, $expat, $element) = @_;
    $self->_debugout(@_);

    # end of a 'configuration' element - save what we have collected within this
    # 'configuration' element and delete the context so as to terminate collection
    # of any subsequently encountered nested elements.

    if (exists $self->{context}->{unitListRef})
    {
        $self->{collected}->{unitListRef} = $self->{context}->{unitListRef};
        delete $self->{context}->{unitListRef};
    }

    if (exists $self->{context}->{buildLayerTargetList})
    {
        # eliminate duplicates
        my %hash = map { $_, '' } @{$self->{context}->{buildLayerTargetList}};
        my @unique = keys %hash;
        $self->{collected}->{buildLayerTargetList} = \@unique;
        delete $self->{context}->{buildLayerTargetList};
    }
}

#-------------------------------------------------------------------------------
# Method 'unitListRef()' accumulates 'unitListRef' unitList information found
# within a 'configuration element with matching name.
#-------------------------------------------------------------------------------
sub unitListRef
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);
    
    if($self->{context}->{intask})
        { return; }     # Task-specific unitListRef not supported

    # if there is a previously created context for 'unitListRef's then store this one.

    if (exists $self->{context}->{unitListRef})
    {
        push @{$self->{context}->{unitListRef}}, $attrs{unitList};
    }
    my $x = 1;
}

#-------------------------------------------------------------------------------
# Methods 'task()' and 'task_()' track context (i.e. inside a task or not)
# because task-specific activities are not supported.
#-------------------------------------------------------------------------------
sub task
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);
    $self->{context}->{intask} = 1;
}

sub task_
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugout(@_);
    $self->{context}->{intask} = 0;
}

#-------------------------------------------------------------------------------
# Method 'buildlayer()' accumulates 'buildlayer' targetList information found
# within a 'configuration element with matching name.
#-------------------------------------------------------------------------------
sub buildLayer
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);

    if (exists $self->{context}->{buildLayerTargetList})
    {
        push @{$self->{context}->{buildLayerTargetList}}, (split /\s+/, $attrs{targetList});
    }
}

#-------------------------------------------------------------------------------
# The following three methods 'unitList()', 'unitList_()' and 'unitRef()'
# accumulate 'unitList' and 'unitRef' information found within the 'build' elements.
#-------------------------------------------------------------------------------
sub unitList
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);

    # start of a 'unitList' element  - create a context so that collection of all
    # 'unitRef's elements found within this 'unitList' element can be collected.

    die "Fatal: context already has unitList\n" if exists $self->{context}->{unitList};
    $self->{context}->{unitList} = { name => $attrs{name}, list => [] };
}

sub unitList_
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugout(@_);

    # end of the current 'unitList' element - save what we have collected
    # and delete the context

    $self->{collected}->{unitList} = {} if ! exists $self->{collected}->{unitList};

    my $unitList = delete $self->{context}->{unitList};
    $self->{collected}->{unitList}->{$unitList->{name}} = $unitList->{list};

}

sub unitRef
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);

    # unitRef found - save unitRef data to current context

    die "Fatal: context requires unitList\n" if ! exists $self->{context}->{unitList};
    push @{$self->{context}->{unitList}->{list}}, $attrs{unit};
}

#-------------------------------------------------------------------------------
# The method 'unit()' accumulates 'unit' information found within the 'systemModel'
# elements.
#-------------------------------------------------------------------------------
sub unit
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);

    # no need to set up a temporary context to collect these since they have global scope
    $self->{collected}->{unit} = {} if ! exists $self->{collected}->{unit};
    $self->{collected}->{unit}->{$attrs{unitID}} = $attrs{bldFile};
}

#-------------------------------------------------------------------------------
# sub option() - accumulates 'option' element information found within the
# 'build' element.
#-------------------------------------------------------------------------------
sub option
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);

    if ($attrs{enable} =~ /[Yy]/)
    {
        # no need to set up a temporary context to collect these since they have global scope
        $self->{collected}->{option} = [] if ! exists $self->{collected}->{option};
        push @{$self->{collected}->{option}}, $attrs{abldOption};
    }
}

#-------------------------------------------------------------------------------
# sub target() - accumulates 'target' element information found within the
# 'build' element.
#-------------------------------------------------------------------------------
sub target
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);

    $self->{collected}->{target} = {} if ! exists $self->{collected}->{target};
    $self->{collected}->{target}->{$attrs{name}} = $attrs{abldTarget};
}

#-------------------------------------------------------------------------------
# sub targetList() - accumulates 'targetList' element information found within the
# 'build' element.
#-------------------------------------------------------------------------------
sub targetList
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);

    $self->{collected}->{targetList} = {} if ! exists $self->{collected}->{targetList};
    my @list = split /\s+/, $attrs{target};
    $self->{collected}->{targetList}->{$attrs{name}} = \@list;
}

#-------------------------------------------------------------------------------
# sub specialInstructions() - sets the 'specialInstructions' flag if a
# 'specialInstructions' element is encountered. In practice, we are only
# interested in instructions which invoke SETUPPRJ.BAT as this will require
# the inclusion of the "bootstrap" line in the output text file.
#-------------------------------------------------------------------------------
sub specialInstructions
{
    my ($self, $expat, $element, %attrs) = @_;
    $self->_debugin(@_);
    if ($attrs{command} =~ /^setupprj.bat/i)
        {
        $self->{collected}->{specialInstructions} = 1;
        }
}

#-------------------------------------------------------------------------------
# utility routines for development/debug purposes.
#-------------------------------------------------------------------------------

sub _debugin
{
##    return;             ## Suppress this debugging!
    my $self = shift;
    my ($ignore0, $ignore2, $element, @args) = @_;
    my $loghandle = $self->{loghandle};
    if ($debugFlag) { print $loghandle "Enter: $element (", (join ' ', @args), ")\n"; }
}

sub _debugout
{
##    return;             ## Suppress this debugging!
    my $self = shift;
    my $loghandle = $self->{loghandle};
    if ($debugFlag) { print $loghandle "Leave: $_[2]\n"; }
}

sub dump
{
    my $self = shift;
    my $fh = shift;

    print $fh "\nDump Collected System Definition\n\n";    
    print $fh "================================\n";    

    if (keys %{$self->{collected}} > 0)
    {
        if (exists $self->{collected}->{option})
        {
            my @option = @{$self->{collected}->{option}};
            print $fh "option :[", (join ',', @option), "]\n";
        }

        if (exists $self->{collected}->{specialInstructions})
        {
            my $flag = $self->{collected}->{specialInstructions};
            print $fh "specialInstructions : '", ($flag ?  "yes" : "no"), "'\n";
        }
        else
        {
            print $fh "specialInstructions : 'no'\n";
        }

        if (exists $self->{collected}->{buildLayerTargetList})
        {
            my @buildLayerTargetList = @{$self->{collected}->{buildLayerTargetList}};
            print $fh "buildLayerTargetList :[", (join ',', @buildLayerTargetList), "]\n";
        }

        if (exists $self->{collected}->{unitListRef})
        {
            my @unitListRef = @{$self->{collected}->{unitListRef}};
            print $fh "unitListRef :[", (join ',', @unitListRef), "]\n";
        }

        if (exists $self->{collected}->{unitList})
        {
            print $fh "unitList:\n{\n";
            my %unitList = %{$self->{collected}->{unitList}};
            for my $key (keys %unitList)
            {
                 my @list = @{$unitList{$key}};
                 print $fh "\t'$key' has units:[", (join ',', @list), "]\n";
            }
            print $fh "}\n";
        }

        if (exists $self->{collected}->{target})
        {
            print $fh "target:\n{\n";
            my %target = %{$self->{collected}->{target}};
            for my $key (keys %target)
            {
                 print $fh "\t'$key' => '", $target{$key} , "'\n";
            }
            print $fh "}\n";
        }

        if (exists $self->{collected}->{targetList})
        {
            print $fh "targetList:\n{\n";
            my %targetList = %{$self->{collected}->{targetList}};
            for my $key (keys %targetList)
            {
                 my @list = @{$targetList{$key}};
                 print $fh "\t'$key' has targets:[", (join ',', @list), "]\n";
            }
            print $fh "}\n";
        }

        if (exists $self->{collected}->{unit})
        {
            print $fh "unit:\n{\n";
            my %unit = %{$self->{collected}->{unit}};
            for my $key (keys %unit)
            {
                 print $fh "\t'$key' => '", $unit{$key} , "'\n";
            }
            print $fh "}\n";
        }
    }
    else
    {
        print $fh "Nothing collected\n";
    }
    print $fh "================================\n";    
}

#-------------------------------------------------------------------------------
# -EOF-
#-------------------------------------------------------------------------------
1;
