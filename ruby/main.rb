require 'json'

require 'xapp/user'
require 'xapp/post'
require 'xapp/feed'
require 'xapp/formatter'
require 'xapp/engagement'
require 'xapp/db'
require 'xapp/store'
require 'xapp/api'

# --- UI layer -------------------------------------------------------------
# A tiny Ruby DSL over React.createElement. No TSX/JSX anywhere.
require 'xapp/ui'
require 'xapp/ui/components/top_bar'
require 'xapp/ui/components/bottom_tabs'
require 'xapp/ui/components/post_card'
require 'xapp/ui/components/composer'
require 'xapp/ui/screens/home'
require 'xapp/ui/screens/search'
require 'xapp/ui/screens/notifications'
require 'xapp/ui/screens/messages'
require 'xapp/ui/root'
require 'xapp/ui/register'
