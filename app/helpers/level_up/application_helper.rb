module LevelUp
  module ApplicationHelper
    def status_tag(status, style)
      content_tag :span, status ? "yes" : "no", class: ["status_tag", (status ? style : "gray")]
    end
  end
end
