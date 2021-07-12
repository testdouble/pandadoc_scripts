require "date"
require "bigdecimal"
require_relative "../cli"
require_relative "../api_key"
require_relative "../api"

module Commands
  module DetectPartiallySignedDocuments
    def self.call(options)
      # Get their API Key if you don't have it
      unless options.api_key
        options.api_key = Cli.in("Enter your PandaDoc API Key")
        ApiKey.store_api_key(options.api_key)
      end

      unless options.internal_domain
        options.internal_domain = Cli.in("Enter your internal e-mail domain name")
      end

      documents = Api.get(
        api_key: options.api_key,
        path: "documents",
        data_key: "results",
        options: {
          status: 5 # translates to "document.viewed", which is what the status will always be for partially-signed documents
        }
      )
      Cli.out "Fetching details on #{documents.size} unsigned documents"

      document_details = documents.map { |d| d["id"] }.map { |document_id|
        Api.get(
          api_key: options.api_key,
          path: "documents/#{document_id}/details",
          data_key: nil,
          options: {}
        )
      }

      docs_needing_signature = document_details.select { |doc|
        internal, external = doc["recipients"].partition { |recipient|
          recipient["email"].end_with?(options.internal_domain)
        }
        external.all? { |r| r["has_completed"] } && !internal.all? { |r| r["has_completed"] }
      }

      if docs_needing_signature.empty?
        Cli.out "Looks good! No unsigned docs are blocked waiting on internal signatures"
      else
        docs_needing_signature.each do |doc|
          signed, not_signed = doc["recipients"].partition { |recipient|
            recipient["has_completed"]
          }
          Cli.out <<~MSG
            Warning: Document "#{doc["name"]}"
              has been signed by recipient(s) #{signed.map { |r| r["email"] }.join(", ")},
              but has NOT been signed by #{not_signed.map { |r| r["email"] }.join(", ")}

            Document URL:
            https://app.pandadoc.com/a/#/documents/#{doc["id"]}
          MSG
        end
      end
    end
  end
end
