require 'jsduck/css/sass_parser'

describe JsDuck::Css::SassParser do

  def parse(string)
    JsDuck::Css::SassParser.new(string).parse
  end

  describe "parsing empty string" do
    let(:docs) { parse("") }

    it "finds no documentation" do
      docs.length.should == 0
    end
  end

  describe "parsing SCSS without doc-comments" do
    let(:docs) do
      parse(<<-EOCSS)
        // some comment
        a:href { color: green; }
        /* Shallalalaaa */
        $foo: 10em !default;
        /*! Goul */
        @mixin goul {
            font-weight: bold;
        }
      EOCSS
    end

    it "finds no documentation" do
      docs.length.should == 0
    end
  end

  describe "parsing SCSS with lots of doc-comments" do
    let(:docs) do
      parse(<<-EOCSS)
        /** some comment */
        a:href { color: green; }
        /** Shallalalaaa */
        $foo: 10em !default;
        /** Goul */
        @mixin goul {
            /** Me too! */
            font-weight: bold;
        }
      EOCSS
    end

    it "finds them all" do
      docs.length.should == 4
    end
  end

  describe "parsing SCSS variable" do
    let(:var) do
      parse(<<-EOCSS)[0]
        /** My variable */
        $foo: 10em !default;
      EOCSS
    end

    it "detects comment" do
      var[:comment].should == "/** My variable */"
    end

    it "detects :css_var type" do
      var[:code][:tagname].should == :css_var
    end

    it "detects name" do
      var[:code][:name].should == "$foo"
    end

    it "detects default value" do
      var[:code][:default].should == "10em"
    end

    it "detects type" do
      var[:code][:type].should == "number"
    end
  end

  describe "parsing SCSS mixin" do
    let(:var) do
      parse(<<-EOCSS)[0]
        /** My mixin */
        @mixin foo($alpha, $beta: 2px) {
            color: $alpha;
        }
      EOCSS
    end

    it "detects comment" do
      var[:comment].should == "/** My mixin */"
    end

    it "detects :css_mixin type" do
      var[:code][:tagname].should == :css_mixin
    end

    it "detects name" do
      var[:code][:name].should == "foo"
    end

    it "detects correct number of parameters" do
      var[:code][:params].length.should == 2
    end

    it "detects name of first param" do
      var[:code][:params][0][:name].should == "$alpha"
    end

    it "detects no default value for first param" do
      var[:code][:params][0][:default].should == nil
    end

    it "detects name of second param" do
      var[:code][:params][1][:name].should == "$beta"
    end

    it "detects default value for second param" do
      var[:code][:params][1][:default].should == "2px"
    end

    it "detects type for second param" do
      var[:code][:params][1][:type].should == "number"
    end
  end

  describe "parsing other SCSS code" do
    let(:var) do
      parse(<<-EOCSS)[0]
        /** My docs */
        .some-class a:href {
            color: #0f0;
        }
      EOCSS
    end

    it "detects comment" do
      var[:comment].should == "/** My docs */"
    end

    it "detects code as :property" do
      var[:code][:tagname].should == :property
    end
  end

  describe "detecting a type" do
    def detect(expr)
      parse("/** */ $var: #{expr};")[0][:code][:type]
    end

    it "plain number --> number" do
      detect("3.14").should == "number"
    end
    it "percentage --> number" do
      detect("10%").should == "number"
    end
    it "measurement --> number" do
      detect("15px").should == "number"
    end

    it "unquoted string --> string" do
      detect("bold").should == "string"
    end
    it "quoted string --> string" do
      detect('"blah blah"').should == "string"
    end

    it "color name --> color" do
      detect("orange").should == "color"
    end
    it "color code --> color" do
      detect("#ff00cc").should == "color"
    end
    it "rgba() --> color" do
      detect("rgba(255, 0, 0, 0.5)").should == "color"
    end
    it "hsl() --> color" do
      detect("hsl(0, 100%, 50%)").should == "color"
    end
    it "fade-in() --> color" do
      detect("fade-in(#cc00cc, 0.2)").should == "color"
    end

    it "true --> boolean" do
      detect("true").should == "boolean"
    end
    it "false --> boolean" do
      detect("false").should == "boolean"
    end

    it "comma-separated list --> list" do
      detect("'Arial', Verdana, sans-serif").should == "list"
    end
    it "space-separated list --> list" do
      detect("2px 4px 2px 4px").should == "list"
    end

    it "null --> nil" do
      detect("null").should == nil
    end
  end

end