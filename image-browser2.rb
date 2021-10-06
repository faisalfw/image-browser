
##
# IMAGE BROWSER
# Oktober 2021
# faisal wahid
##

require "mechanize"
require "nokogiri"
require "down"
require "pry"
require "mini_mime"

require "Qt"
include Qt

Down.backend :wget

def get_image_links(image_to_search)
	url = 'https://images.google.com/'
	search_for = image_to_search
	search_for = "Horses" if search_for.empty?
	ret = []

	session = Mechanize.new

	page = session.get url

	form = page.forms.first
	form.q = search_for

	result = session.submit form, form.buttons.first

	nodes = result.search 'div img'
	image_links = []
	nodes.each { |node|
		src = node[:src]
		image_links << src if src =~ /^https/
	}

	return image_links
end

def download_image(image_link)
	tempfile = Down.download(image_link)
	return tempfile
end

class MyWindow < Widget

	def initialize
		super
		setup
	end

	def setup
		resize 550, 500
		setFixedSize 550, 500

		@hbox = HBoxLayout.new
		@edit = LineEdit.new "dress"
		@button = PushButton.new "search"
		@hbox.addWidget @edit
		@hbox.addWidget @button

		@hbox2 = HBoxLayout.new
		@vbox1 = VBoxLayout.new
		@vbox2 = VBoxLayout.new
		@vbox3 = VBoxLayout.new
		[@vbox1, @vbox2, @vbox3].each { |vbox| @hbox2.addLayout(vbox) }

		@scroll = ScrollArea.new
		@scroll.setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn)
		@scroll.setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff)
		@scroll.setWidgetResizable(true)
		#@scroll.setWidget(widget)

		@widget = Widget.new
		@widget.setLayout(@hbox2)
		@scroll.setWidget(@widget)

		@vbox4 = VBoxLayout.new
		@vbox4.addLayout(@hbox)
		@vbox4.addWidget(@scroll)

		setLayout(@vbox4)

		Qt::Object.connect(
			@button, SIGNAL("clicked()"),
			self, SLOT("search()")
		)
	end

	def delete_all_items_in_layout(layout)
		(0...layout.count).each { |n|
			layout.takeAt(0).widget.close
		}
	end

	slots "search()"
	def search
		[@vbox1, @vbox2, @vbox3].each { |layout| delete_all_items_in_layout(layout)}
		image_links = get_image_links(@edit.text.to_s)
		Thread.new {
			image_links.each { |link|
				tempfile = download_image(link)
				# puts tempfile.path
				Qt.execute_in_main_thread do
					[@vbox1, @vbox2, @vbox3].sample.addWidget(
						Label.new("<img src='#{tempfile.path}'>")
					)
				end
			}
		}
	end

end

app = Application.new []

MyWindow.new.show

app.exec

# the scraper part is bad
# the Qt library is complex
# maybe in thefuture, 
# both will be more simple
# and of course, better
