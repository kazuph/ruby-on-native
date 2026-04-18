# backtick_javascript: true
module XApp
  module UI
    # Hand our Root component off to the JS bridge so App.tsx can return it.
    `__RN__.setRoot(#{XApp::UI::Root})`
  end
end
