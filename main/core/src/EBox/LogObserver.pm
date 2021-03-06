# Copyright (C) 2006-2007 Warp Networks S.L.
# Copyright (C) 2008-2013 Zentyal S.L.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Class: EBox::LogObserver
#
#       Those modules FIXME to process logs generated by their
#       daemon or servide must inherit from this class and implement
#       the given interface
#
use strict;
use warnings;

package EBox::LogObserver;

use Perl6::Junction qw(any);

sub new
{
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

# Method: logHelper
#
# Returns:
#
#       An object implementing EBox::LogHelper
sub logHelper
{
    return undef;
}

# Method: enableLog
#
#   This method must be overriden by the class implementing this interface,
#   if it needs to enable or disable logging facilities in the services its
#   managing.
#
# Parameters:
#
#   enable - boolean, true if it's enabled, false it's disabled
#
sub enableLog
{
}

# Method: tableInfo
#
#       This function returns an array of hash ref or a single hash
#       ref with these fields:
#
#        - name: the printable name of the table
#        - tablename: the name of the database table associated with the module.
#        - titles: A hash ref with the table fields and theirs user read
#               translation.
#        - order: An array with table fields ordered.
#        - timecol: The timestamp column to perform date filtering
#        - eventcol : The column which stores the events related to the row
#        - events: Hash ref containing the possible event choices, the key
#                  is the stored value in the DB and the value is the i18ned name for that event
#        - filter: Array ref of the field names that can perform filtering
#        - autoFilter: hash reference with filters to be applied always to the table info. In the format column name => value.
#                      Explicit filter if exists take precedence.
#
#   Warning:
#    -use lowercase in column names
sub tableInfo
{
    throw EBox::Exceptions::NotImplemented;
}

# Method: reportUrls
#
#     return the module's rows for the SelectLog table.
#
sub reportUrls
{
    my ($self) = @_;

    my @tableInfos;
    my $ti = $self->tableInfo();
    if (ref $ti eq 'HASH') {
        EBox::warn('tableInfo() in ' . $self->name .
                ' must return a reference to a list of hashes not the hash itself');
        @tableInfos = ( $ti );
    } else {
        @tableInfos = @{ $ti };
    }

    my @urls;
    foreach my $tableInfo (@tableInfos) {
        my $index = $tableInfo->{tablename};
        my $rawUrl = "/Logs/Index?selected=$index&refresh=1";

        push @urls, { domain => $tableInfo->{name},  raw => $rawUrl, };
    }

    return \@urls;
}


# Method: humanEventMessage
#
#      Given a row with the table description given by
#      <EBox::LogObserver::tableInfo> it will return a human readable
#      message to inform admin using events.
#
#      To be overriden by subclasses. Default behaviour is showing
#      every field name following by a colon and the value.
#
# Parameters:
#
#      row - hash ref the row returned by <EBox::Logs::search>
#
# Returns:
#
#      String - the i18ned human readable message to send in an event
#
sub humanEventMessage
{
    my ($self, $row) = @_;

    my @tableInfos;
    my $tI = $self->tableInfo();
    if ( ref($tI) eq 'HASH' ) {
        EBox::warn('tableInfo() in ' . $self->name()
                   . ' must return a reference to a '
                   . 'list of hashes not the hash itself');

        @tableInfos = ( $tI );
    } else {
        @tableInfos = @{ $tI };
    }
    my $message = q{};
    foreach my $tableInfo (@tableInfos) {
        next unless (exists($tableInfo->{events}->{$row->{event}}));
        foreach my $field (@{$tableInfo->{order}}) {
            if ( $field eq $tableInfo->{eventcol} ) {
                $message .= $tableInfo->{titles}->{$tableInfo->{eventcol}}
                  . ': ' . $tableInfo->{events}->{$row->{$field}} . ' ';
            } else {
                my $rowContent = $row->{$field};
                # Delete trailing spaces
                $rowContent =~ s{ \s* \z}{}gxm;
                $message .= $tableInfo->{titles}->{$field} . ": $rowContent ";
            }
        }
    }
    return $message;

}

sub _compositeUsesDbTable
{
    my ($self, $composite, $dbTables_r) = @_;

    my $usesDbTable = 0;
    foreach my $component (@{ $composite->components() } ) {
        if ($component->can('dbTableName')) {
            if ($component->dbTableName() eq any( @{ $dbTables_r } )) {
                $usesDbTable = 1;
            }

            last;
        }
    }

    return $usesDbTable;
}

1;
