RSpec.describe CallSheet::Transaction do
  subject(:container) {
    {
      upcase: -> input { input.upcase },
      reverse: -> input { input.reverse },
      remove_odd_words: -> input { input.split(" ").each_with_index.reject { |_, i| i.odd? }.map(&:first).join(" ") },
      exclaim_all: -> input { input.split(" ").map { |str| str + "!" }.join(" ") },
    }
  }

  describe "#+" do
    let(:initial_transaction) {
      CallSheet(container: container) do
        map :upcase
      end
    }
    let(:other_transaction) {
      CallSheet(container: container) do
        map :remove_odd_words
      end
    }
    let!(:new_transaction) { initial_transaction + other_transaction }

    it "appends the transaction" do
      expect(new_transaction.call("the quick brown fox").right).to eq "THE BROWN"
    end

    it "leaves the original transaction unmodified" do
      expect(initial_transaction.call("the quick brown fox").right).to eq "THE QUICK BROWN FOX"
    end
  end

  describe "#remove" do
    let(:initial_transaction) {
      CallSheet(container: container) do
        map :upcase
        map :remove_odd_words
        map :reverse
      end
    }

    let!(:new_transaction) { initial_transaction.remove(:remove_odd_words, :reverse) }

    it "removes the specified steps" do
      expect(new_transaction.call("the quick brown fox").right).to eq "THE QUICK BROWN FOX"
    end

    it "leaves the original transaction unmodified" do
      expect(initial_transaction.call("the quick brown fox").right).to eq "NWORB EHT"
    end
  end

  describe "#insert" do
    let(:initial_transaction) {
      CallSheet(container: container) do
        map :upcase
        map :reverse
      end
    }

    context "before" do
      let!(:new_transaction) {
        initial_transaction.insert(before: :reverse) do
          map :exclaim_all
        end
      }

      it "inserts the new steps before the specified one" do
        expect(new_transaction.call("the quick brown fox").right).to eq "!XOF !NWORB !KCIUQ !EHT"
      end

      it "leaves the original transaction unmodified" do
        expect(initial_transaction.call("the quick brown fox").right).to eq "XOF NWORB KCIUQ EHT"
      end
    end

    context "after" do
      let!(:new_transaction) {
        initial_transaction.insert(after: :reverse) do
          map :exclaim_all
        end
      }

      it "inserts the new steps after the specified one" do
        expect(new_transaction.call("the quick brown fox").right).to eq "XOF! NWORB! KCIUQ! EHT!"
      end

      it "leaves the original transaction unmodified" do
        expect(initial_transaction.call("the quick brown fox").right).to eq "XOF NWORB KCIUQ EHT"
      end
    end
  end
end
