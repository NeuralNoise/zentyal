# Copyright (C) 2011-2012 eBox Technologies S.L.
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


package EBox::Virt::Model::NetworkSettings;

# Class: EBox::Virt::Model::NetworkSettings
#
#      Table with the network interfaces of the Virtual Machine
#

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Types::Select;
use EBox::Types::Text;
use EBox::Types::MACAddr;

use constant MAX_IFACES => 8;

# Group: Private methods

sub _populateIfaceTypes
{
    return [
            { value => 'nat', printableValue => 'NAT' },
            { value => 'bridged', printableValue => __('Bridged') },
            { value => 'internal', printableValue => __('Internal Network') },
    ];
}

sub _populateIfaces
{
    my $virt = EBox::Global->modInstance('virt');

    my @values = map {
                        { value => $_, printableValue => $_ }
                     } $virt->ifaces();

    unshift @values, { value => 'none', printableValue => __('None'),  };
    return \@values;
}

# Method: _table
#
# Overrides:
#
#      <EBox::Model::DataTable::_table>
#
sub _table
{
    my @tableHeader = (
       new EBox::Types::Select(
                               fieldName     => 'type',
                               printableName => __('Type'),
                               populate      => \&_populateIfaceTypes,
                               editable      => 1,
                              ),
       new EBox::Types::Select(
                               fieldName     => 'iface',
                               printableName => __('Bridged to'),
                               populate      => \&_populateIfaces,
                               disableCache  => 1,
                               editable      => 1,
                              ),
       new EBox::Types::Text(
                             fieldName     => 'name',
                             printableName => __('Internal Network Name'),
                             editable      => 1,
                             optional      => 1,
                             optionalLabel => 0,
                            ),
       new EBox::Types::MACAddr(
                           fieldName     => 'mac',
                           printableName => __('MAC Address'),
                           editable      => 1,
                           unique        => 1,
                           defaultValue  => \&randomMAC,
                          ),

    );

    my $dataTable =
    {
        tableName          => 'NetworkSettings',
        printableTableName => __('Network Settings'),
        printableRowName   => __('interface'),
        defaultActions     => [ 'add', 'del', 'editField', 'changeView', 'move' ],
        tableDescription   => \@tableHeader,
        order              => 1,
        enableProperty     => 1,
        defaultEnabledValue => 1,
        class              => 'dataTable',
        help               => __('Here you can define the network interfaces of the virtual machine.'),
        modelDomain        => 'Virt',
    };

    return $dataTable;
}

sub randomMAC
{
    my ($self) = @_;

    my $mac = '';
    foreach my $i (0 .. 5) {
        $mac .= sprintf("%02X", int(rand(255)));
        if ($i < 5) {
            $mac .= ':';
        }
    }

    return $mac;
}

# Method: validateTypedRow
#
# Overrides:
#
#      <EBox::Model::DataTable::validateTypedRow>
#
sub validateTypedRow
{
    my ($self, $action, $changedFields, $allFields) = @_;
    if (@{$self->ids()} >= MAX_IFACES) {
        throw EBox::Exceptions::External(__x('A maximum of {num} network interfaces are allowed', num => MAX_IFACES));
    }

    my $type = exists $changedFields->{type} ?
        $changedFields->{type}->value() : $allFields->{type}->value();
    if ($type eq 'bridged') {
        my $iface = exists $changedFields->{iface} ?
            $changedFields->{iface}->value() : $allFields->{iface}->value();
        if ($iface eq 'none') {
            if (not $self->{confmodule}->allowsNoneIface()) {
                throw EBox::Exceptions::External(
                    __("'None' interface is not allowed in your virtual machine backend")
                   );
            }
        }
    }
}

# Method: viewCustomizer
#
#   Overrides <EBox::Model::DataTable::viewCustomizer>
#
sub viewCustomizer
{
    my ($self) = @_;

    my $customizer = new EBox::View::Customizer();
    $customizer->setModel($self);

    $customizer->setHTMLTitle([]);

    $customizer->setOnChangeActions(
            { type =>
                {
                  'nat' => { hide => [ 'iface', 'name' ] },
                  'bridged' => { show  => [ 'iface' ], hide => [ 'name' ] },
                  'internal' => { show  => [ 'name' ], hide => [ 'iface' ] },
                }
            });
    return $customizer;
}

sub ifaceMethodChanged
{
    my ($self, $iface, $oldmethod, $newmethod) = @_;

    if ($newmethod ne 'notset') {
        return;
    }

    foreach my $id (@{ $self->ids() }) {
        my $row = $self->row($id);
        my $rowIface =$row->valueByName('iface');
        $rowIface or
            next;
        if ($rowIface eq $iface) {
            return 1;
        }
    }

    return undef;
}


sub freeIface
{
    my ($self , $iface) = @_;

    my $rowId;
    foreach my $id (@{ $self->ids() }) {
        my $row = $self->row($id);
        my $rowIface =$row->valueByName('iface');
        $rowIface or
            next;
        if ($rowIface eq $iface) {
            $rowId = $id;
            last;
        }
    }

    if ($rowId) {
        if ($self->{confmodule}->allowsNoneIface()) {
            my $row = $self->row($rowId);
            my $iface = $row->elementByName('iface');
            $iface->setValue('none');
            $row->store();
        } else {
            $self->removeRow($rowId);
        }
    }
}

1;
