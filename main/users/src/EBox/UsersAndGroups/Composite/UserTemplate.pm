# Copyright (C) 2010-2013 Zentyal S.L.
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

# Class: EBox::UsersAndGroups::Composite::UserTemplate

use strict;
use warnings;

package EBox::UsersAndGroups::Composite::UserTemplate;

use base 'EBox::Model::Composite';

use EBox::Gettext;
use EBox::Global;

# Group: Protected methods

# Method: _description
#
# Overrides:
#
#     <EBox::Model::Composite::_description>
#
sub _description
{
    my $users = EBox::Global->modInstance('users');

    my $description = {
        layout          => 'top-bottom',
        name            => 'UserTemplate',
        compositeDomain => 'Users',
        help => __('These configuration options are used when a new user ' .
            'account is created.')
    };

    return $description;
}

# Method: componentNames
#
# Overrides:
#
#     <EBox::Model::Composite::componentNames>
#
sub componentNames
{
    my $users = EBox::Global->modInstance('users');

    my @models;
    if ($users->mode() eq 'master') {
        push (@models, 'AccountSettings');
    }

    push (@models, @{$users->defaultUserModels()});

    return \@models;
}

sub pageTitle
{
    return __('User Template');
}

sub menuFolder
{
    return 'UsersAndGroups';
}

1;
