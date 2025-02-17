defmodule AWS.CodeGen.DocstringTest do
  use ExUnit.Case
  alias AWS.CodeGen.Docstring

  describe "format/2" do
    test "returns an empty string when nil is provided" do
      assert "" == Docstring.format(:elixir, nil)
      assert "" == Docstring.format(:erlang, nil)
    end

    test "is effectively a no-op when an empty string is provided" do
      assert "" == Docstring.format(:elixir, "")
      assert "" == Docstring.format(:erlang, "")
    end

    test "converts tags to Markdown and indents the text by 2 spaces" do
      text = "<p>Hello,</p> <p><code>world</code></p>!"
      assert "  Hello,\n\n  `world`\n\n  !" == Docstring.format(:elixir, text)

      assert "%% @doc Hello,\n%%\n%% `world'\n%%\n%% !" ==
               Docstring.format(:erlang, text)
    end

    test "keeps the text formated according to ExDoc" do
      text = """
      The UpdateTimeToLive method enables or disables Time to Live (TTL) for the specified table. A successful UpdateTimeToLive call returns the current TimeToLiveSpecification. It can take up to one hour for the change to fully process. Any additional UpdateTimeToLive calls for the same table during this one hour duration result in a ValidationException.

      <div class="seeAlso"><a href="http://bar.com">foo</a></div>
      """

      assert String.trim(
               """
                 The UpdateTimeToLive method enables or disables Time to Live (TTL) for the
                 specified table.

                 A successful UpdateTimeToLive call returns the current TimeToLiveSpecification.
                 It can take up to one hour for the change to fully process. Any additional
                 UpdateTimeToLive calls for the same table during this one hour duration result
                 in a ValidationException.

                 See also: [foo](http://bar.com)
               """,
               "\n"
             ) == Docstring.format(:elixir, text)
    end

    test "preserves markdown links in one line even if it takes more space" do
      text = """
      Retrieves a list of findings generated by the specified analyzer. To learn about filter keys that you can use to create an archive rule, see [Access Analyzer filter keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-reference-filter-keys.html) in the **IAM User Guide**.
      """

      assert String.trim(
               """
                 Retrieves a list of findings generated by the specified analyzer.

                 To learn about filter keys that you can use to create an archive rule, see
                 [Access Analyzer filter keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-reference-filter-keys.html)
                 in the **IAM User Guide**.
               """,
               "\n"
             ) == Docstring.format(:elixir, text)
    end

    test "transforms ul lists into markdown lists" do
      text = """
      A short-description.

      **About Permissions**

      <ul> <li> If the private CA and the certificates it issues reside in the same account, you can use `CreatePermission` to grant permissions for ACM to carry out automatic certificate renewals.
      <ul><li>subitem 1</li><li>subitem 2</li></ul>

      </li> <li> For automatic certificate renewal to succeed, the ACM service principal needs permissions to create, retrieve, and list certificates.

      </li> <li> If the private CA and the ACM certificates reside in different accounts, then permissions cannot be used to enable automatic renewals. Instead, the ACM certificate owner must set up a resource-based policy to enable cross-account issuance and renewals. For more information, see [Using a Resource Based Policy with ACM Private CA](acm-pca/latest/userguide/pca-rbp.html).
      </li> </ul>
      """

      expected =
        String.trim(
          """
            A short-description.

            ## About Permissions

              * If the private CA and the certificates it issues reside in the
            same account, you can use `CreatePermission` to grant permissions for ACM to
            carry out automatic certificate renewals.
                * subitem 1
                * subitem 2

              * For automatic certificate renewal to succeed, the ACM service
            principal needs permissions to create, retrieve, and list certificates.

              * If the private CA and the ACM certificates reside in different
            accounts, then permissions cannot be used to enable automatic renewals. Instead,
            the ACM certificate owner must set up a resource-based policy to enable
            cross-account issuance and renewals. For more information, see [Using a Resource Based Policy with ACM Private CA](acm-pca/latest/userguide/pca-rbp.html).
          """,
          "\n"
        )

      assert expected == Docstring.format(:elixir, text)
    end

    test "transforms ol lists into markdown numered lists" do
      text = """
      A short-description.

      <ol> <li> First

      </li> <li> Second

      </li> <li> Third
      </li> </ol>
      """

      expected =
        String.trim(
          """
            A short-description.

              1. First

              2. Second

              3. Third
          """,
          "\n"
        )

      assert expected == Docstring.format(:elixir, text)
    end

    test "transforms dl tags in definition blocks" do
      text = """
      A short-description.

      <dl>
        <dt>Term</dt>
        <dd>Explanation <em>Emphasis</em></dd>
        <dt>Second term</dt>
        <dd>Details</dd>
      </dl>
      """

      expected =
        String.trim(
          """
            A short-description.

            ## Definitions

            ### Term

            Explanation *Emphasis*

            ### Second term

            Details
          """,
          "\n"
        )

      assert expected == Docstring.format(:elixir, text)
    end

    test "removes some tags and add spacing after them" do
      text = """
      <p>A short description</p>

      <div>This is a div</div>
      <fullname>Fullname node</fullname>
      <note>Here is a note</note>
      <div class="seeAlso">See also div</div>
      """

      expected =
        String.trim(
          """
          %% @doc A short description
          %%
          %% This is a div
          %%
          %% Fullname node
          %%
          %% Here is a note
          %%
          %% See also: See also div
          """,
          "\n"
        )

      assert expected == Docstring.format(:erlang, text)
    end

    test "formats a, code and p (as title) tags" do
      text = """
      A short description. This is a <a href="https://foo.bar">link</a>.
      This is a <code>code</code> and a multiline is here:
      <code>
      puts "hello"
      </code>
      <p class="title">Section title</p>
      Here is a link with the same text: <a href="https://foo">https://foo</a>
      And a link without href: <a>without href</a>
      """

      expected =
        String.trim(
          """
          %% @doc A short description.
          %%
          %% This is a <a href="https://foo.bar">link</a>.
          %% This is a `code' and a multiline is here:
          %%
          %% ```
          %% puts &quot;hello&quot;
          %% '''
          %%
          %% == Section title ==
          %%
          %% Here is a link with the same text: [https://foo]
          %% And a link without href: `without href'
          """,
          "\n"
        )

      assert expected == Docstring.format(:erlang, text)
    end
  end

  test "html_to_markdown/1 replaces <code> tags with backticks" do
    text = "Hello, <code>world</code>!"
    assert "Hello, `world`!" == Docstring.html_to_markdown(text)
  end

  test "html_to_markdown/1 strips <fullname> tags and renders text as a paragraph" do
    text = "<fullname>Hello, world!</fullname>"
    assert "Hello, world!\n\n" == Docstring.html_to_markdown(text)
  end

  test "html_to_markdown/1 converts <p> tags to newline-separated paragraphs" do
    text = "<p>Hello,</p> <p>world!</p>"
    assert "Hello,\n\n world!\n\n" == Docstring.html_to_markdown(text)

    text = "<p class=\"title\">Hello,</p> <p>world!</p>"
    assert "Hello,\n\n world!\n\n" == Docstring.html_to_markdown(text)
  end

  test "html_to_markdown/1 converts <a> tags to Markdown links" do
    text = ~s(<a href="http://example.com">Hello, world!</a>)
    expected = ~s<[Hello, world!](http://example.com)>
    assert expected == Docstring.html_to_markdown(text)
  end

  test "html_to_markdown/1 replaces bare <a> tags with backticks" do
    text = "<a>Hello, world!</a>"
    assert "`Hello, world!`" == Docstring.html_to_markdown(text)
  end

  test "html_to_markdown/1 converts multiple <a> tags to Markdown links" do
    text = ~s(<a href="http://example.com">Hello, world!</a>)
    expected = ~s<[Hello, world!](http://example.com)>
    assert "#{expected} #{expected}" == Docstring.html_to_markdown("#{text} #{text}")
  end

  test "html_to_markdown/1 replaces <i> tags with asterisks" do
    text = "<i>Hello, world!</i>"
    assert "*Hello, world!*" == Docstring.html_to_markdown(text)
  end

  test "html_to_markdown/1 replaces <b> tags with double-asterisks" do
    text = "<b>Hello, world!</b>"
    assert "**Hello, world!**" == Docstring.html_to_markdown(text)
  end

  test "split_paragraphs/1 converts a single paragraph to a single item list" do
    assert ["Hello, world!"] == Docstring.split_paragraphs("Hello, world!")
  end

  test "split_paragraphs/1 splits paragraphs and returns them in a list" do
    paragraphs = "Hello, world!\nHow are you?"
    expected = ["Hello, world!", "How are you?"]
    assert expected == Docstring.split_paragraphs(paragraphs)
  end

  test "justify_line/2 is a no-op if the line to justify is empty" do
    assert "" == Docstring.justify_line("")
  end

  test "justify_line/2 is a no-op if the line to justify is shorter than the requested length" do
    assert "  Hello, world!" == Docstring.justify_line("Hello, world!")
  end

  test "justify_line/2 splits lines and strips trailing whitespace so that each line is shorter than the requested length" do
    assert "  Hello,\n  world!" == Docstring.justify_line("Hello, world!", 7)
  end

  test "justify_line/2 splits lines as early as possible when a word is longer than the requested length" do
    assert "  Hello,\n  world!\n" == Docstring.justify_line("Hello, world!", 3)
  end
end
