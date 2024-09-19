require "rails_helper"

describe RemoteTranslations::Microsoft::Client do
  let(:client) { RemoteTranslations::Microsoft::Client.new }

  describe "#call" do
    context "when characters from request are less than the characters limit" do
      it "response has the expected result" do
        response = ["Nuevo título", "Nueva descripción"]

        expect_any_instance_of(BingTranslator).to receive(:translate_array).and_return(response)

        result = client.call(["New title", "New description"], :es)

        expect(result).to eq(["Nuevo título", "Nueva descripción"])
      end

      it "response nil has the expected result when request has nil value" do
        response = ["Notranslate", "Nueva descripción"]

        expect_any_instance_of(BingTranslator).to receive(:translate_array).and_return(response)

        result = client.call([nil, "New description"], :es)

        expect(result).to eq([nil, "Nueva descripción"])
      end
    end

    context "when characters from request are greater than characters limit" do
      it "has the expected result when the request has two texts and both are smaller than the limit" do
        stub_const("RemoteTranslations::Microsoft::Client::CHARACTERS_LIMIT_PER_REQUEST", 20)
        text_en = Faker::Lorem.characters(number: 11)
        another_text_en = Faker::Lorem.characters(number: 11)

        translated_text_es = Faker::Lorem.characters(number: 11)
        another_translated_text_es = Faker::Lorem.characters(number: 11)
        response_text = [translated_text_es]
        response_another_text = [another_translated_text_es]

        expect_any_instance_of(BingTranslator).to receive(:translate_array).exactly(1)
                                                                           .times
                                                                           .and_return(response_text)
        expect_any_instance_of(BingTranslator).to receive(:translate_array).exactly(1)
                                                                           .times
                                                                           .and_return(response_another_text)

        result = client.call([text_en, another_text_en], :es)

        expect(result).to eq([translated_text_es, another_translated_text_es])
      end

      it "has the expected result when the request has two texts and both are greater than the limit" do
        stub_const("RemoteTranslations::Microsoft::Client::CHARACTERS_LIMIT_PER_REQUEST", 20)
        start_text_en = Faker::Lorem.characters(number: 10) + " "
        end_text_en = Faker::Lorem.characters(number: 10)
        text_en = start_text_en + end_text_en

        start_translated_text_es = Faker::Lorem.characters(number: 10) + " "
        end_translated_text_es = Faker::Lorem.characters(number: 10)
        translated_text_es = start_translated_text_es + end_translated_text_es
        response_start_text = [start_translated_text_es]
        response_end_text = [end_translated_text_es]

        expect_any_instance_of(BingTranslator).to receive(:translate_array).with([start_text_en], to: :es)
                                                                           .exactly(1)
                                                                           .times
                                                                           .and_return(response_start_text)
        expect_any_instance_of(BingTranslator).to receive(:translate_array).with([end_text_en], to: :es)
                                                                           .exactly(1)
                                                                           .times
                                                                           .and_return(response_end_text)

        start_another_text_en = Faker::Lorem.characters(number: 12) + "."
        end_another_text_en = Faker::Lorem.characters(number: 12)
        another_text_en = start_another_text_en + end_another_text_en

        another_start_translated_text_es = Faker::Lorem.characters(number: 12) + "."
        another_end_translated_text_es = Faker::Lorem.characters(number: 12)
        another_translated_text_es = another_start_translated_text_es + another_end_translated_text_es
        response_another_start_text = [another_start_translated_text_es]
        response_another_end_text = [another_end_translated_text_es]

        expect_any_instance_of(BingTranslator).to(receive(:translate_array)
                                                  .with([start_another_text_en], to: :es)
                                                  .exactly(1)
                                                  .times
                                                  .and_return(response_another_start_text))
        expect_any_instance_of(BingTranslator).to(receive(:translate_array)
                                                  .with([end_another_text_en], to: :es)
                                                  .exactly(1)
                                                  .times
                                                  .and_return(response_another_end_text))

        result = client.call([text_en, another_text_en], :es)

        expect(result).to eq([translated_text_es, another_translated_text_es])
      end
    end
  end

  describe "#detect_split_position" do
    context "text has less characters than characters limit" do
      it "does not split the text" do
        stub_const("RemoteTranslations::Microsoft::Client::CHARACTERS_LIMIT_PER_REQUEST", 20)
        text_to_translate = Faker::Lorem.characters(number: 10)

        result = client.fragments_for(text_to_translate)

        expect(result).to eq [text_to_translate]
      end
    end

    context "text has more characters than characters limit" do
      it "to split text by first valid dot when there is a dot for split" do
        stub_const("RemoteTranslations::Microsoft::Client::CHARACTERS_LIMIT_PER_REQUEST", 20)
        start_text = Faker::Lorem.characters(number: 10) + "."
        end_text = Faker::Lorem.characters(number: 10)
        text_to_translate = start_text + end_text

        result = client.fragments_for(text_to_translate)

        expect(result).to eq([start_text, end_text])
      end

      it "to split text by first valid space when there is not a dot for split but there is a space" do
        stub_const("RemoteTranslations::Microsoft::Client::CHARACTERS_LIMIT_PER_REQUEST", 20)
        start_text = Faker::Lorem.characters(number: 10) + " "
        end_text = Faker::Lorem.characters(number: 10)
        text_to_translate = start_text + end_text

        result = client.fragments_for(text_to_translate)

        expect(result).to eq([start_text, end_text])
      end

      it "to split text in the middle of a word when there are not valid dots and spaces" do
        stub_const("RemoteTranslations::Microsoft::Client::CHARACTERS_LIMIT_PER_REQUEST", 40)
        sub_part_text_1 = Faker::Lorem.characters(number: 5) + " ."
        sub_part_text_2 = Faker::Lorem.characters(number: 5)
        sub_part_text_3 = Faker::Lorem.characters(number: 9)
        sub_part_text_4 = Faker::Lorem.characters(number: 30)
        text_to_translate = sub_part_text_1 + sub_part_text_2 + sub_part_text_3 + sub_part_text_4

        result = client.fragments_for(text_to_translate)

        expect(result).to eq([sub_part_text_1 + sub_part_text_2, sub_part_text_3 + sub_part_text_4])
      end
    end
  end
end
