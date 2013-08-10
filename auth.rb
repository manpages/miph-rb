require 'octokit'
require 'yaml'
 
class GitHubAuth
  NOTE = "MIPh-rb: GitHub for kids."
  SCOPES = ["user", "repo"]
  CREDENTIALS = File.join("#{ENV['HOME']}", ".config", "miph.yml")
 
  def self.client
    new.client
  end
 
  def client
    @client ||= lambda do
      unless File.exist?(CREDENTIALS)
        authenticate
      end
      Octokit::Client.new(YAML.load_file(CREDENTIALS))
    end.call
  end
 
  private
  def authenticate
    login = password = token = ""
    login = `git config github.user`.chomp
    login = ask_login if login.empty?
    password = ask_password
    auth_client = Octokit::Client.new(:login => login, :password => password)
    auth = auth_client.authorizations.detect { |a| a.note == NOTE }
    unless auth
      auth = auth_client.create_authorization(:scopes => SCOPES, :note => NOTE)
    end
    File.open(CREDENTIALS, 'w') do |f|
      f.puts({ :login => login, :oauth_token => auth.token }.to_yaml)
    end
  end
 
  def ask_login
    p "Enter your GitHub username"
    $stdin.gets.chomp
  end
 
  # No-echo password input, stolen from Defunkt's `hub`
  # Won't work in Windows
  def ask_password
    p "Enter your GitHub password (this will NOT be stored)"
    tty_state = `stty -g`
    system 'stty raw -echo -icanon isig' if $?.success?
    pass = ''
    while char = $stdin.getbyte and not (char == 13 or char == 10)
      if char == 127 or char == 8
        pass[-1,1] = '' unless pass.empty?
      else
        pass << char.chr
      end
    end
    pass
  ensure
    system "stty #{tty_state}" unless tty_state.empty?
  end
end
