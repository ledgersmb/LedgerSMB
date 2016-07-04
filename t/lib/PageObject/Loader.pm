package PageObject::Loader;

use strict;
use warnings;


# SETUP


use PageObject::Setup::Admin;
use PageObject::Setup::CreateUser;
use PageObject::Setup::CredsSection;
use PageObject::Setup::EditUser;
use PageObject::Setup::Login;
use PageObject::Setup::OperationConfirmation;
use PageObject::Setup::UsersList;


# APP

use PageObject::App;
use PageObject::App::Initial;
use PageObject::App::Login;
use PageObject::App::Menu;
use PageObject::App::Main;

1;
