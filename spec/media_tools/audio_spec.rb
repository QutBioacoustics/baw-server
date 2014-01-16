require 'spec_helper'
require 'modules/audio'
require 'modules/exceptions'

describe MediaTools::AudioMaster do

  # mp3, webm, ogg (wav, wv)
  let(:duration_range) { 0.07 }

  let(:audio_file_mono) { File.join(File.dirname(__FILE__), 'test-audio-mono.ogg') }
  let(:audio_file_mono_media_type) { Mime::Type.lookup('audio/ogg') }
  let(:audio_file_mono_sample_rate) { 44100 }
  let(:audio_file_mono_channels) { 1 }
  let(:audio_file_mono_duration_seconds) { 70 }

  let(:audio_file_stereo) { File.join(File.dirname(__FILE__), 'test-audio-stereo.ogg') }
  let(:audio_file_stereo_media_type) { Mime::Type.lookup('audio/ogg') }
  let(:audio_file_stereo_sample_rate) { 44100 }
  let(:audio_file_stereo_channels) { 2 }
  let(:audio_file_stereo_duration_seconds) { 70 }

  let(:audio_file_3_channels) { File.join(File.dirname(__FILE__), 'test-audio-3-channels.ogg') }
  let(:audio_file_3_channels_media_type) { Mime::Type.lookup('audio/ogg') }
  let(:audio_file_3_channels_sample_rate) { 44100 }
  let(:audio_file_3_channels_channels) { 3 }
  let(:audio_file_3_channels_duration_seconds) { 10 }

  let(:audio_file_empty) { File.join(File.dirname(__FILE__), 'test-audio-empty.ogg') }
  let(:audio_file_corrupt) { File.join(File.dirname(__FILE__), 'test-audio-corrupt.ogg') }
  let(:audio_file_does_not_exist_1) { File.join(File.dirname(__FILE__), 'not-here-1.ogg') }
  let(:audio_file_does_not_exist_2) { File.join(File.dirname(__FILE__), 'not-here-2.ogg') }
  let(:temp_dir) { File.join(File.dirname(__FILE__), '..', '..', 'tmp') }
  let(:audio_master) { MediaTools::AudioMaster.new(temp_dir) }
  let(:temp_audio_file_1) { File.join(temp_dir, 'temp-audio-1') }
  let(:temp_audio_file_2) { File.join(temp_dir, 'temp-audio-2') }
  let(:temp_audio_file_3) { File.join(temp_dir, 'temp-audio-3') }
  let(:temp_audio_file_4) { File.join(temp_dir, 'temp-audio-4') }


  after(:each) do
    Dir.glob(temp_audio_file_1+'*.*').each { |f| File.delete(f) }
    Dir.glob(temp_audio_file_2+'*.*').each { |f| File.delete(f) }
    Dir.glob(temp_audio_file_3+'*.*').each { |f| File.delete(f) }
    Dir.glob(temp_audio_file_4+'*.*').each { |f| File.delete(f) }
  end

  context 'when getting audio file information' do
    it 'runs to completion when given an existing file' do
      audio_master.info(audio_file_stereo)
    end

    it 'causes exception for invalid path' do
      expect {
        audio_master.info(audio_file_does_not_exist_1)
      }.to raise_error(Exceptions::FileNotFoundError)
    end

    it 'gives correct error for empty file' do
      expect {
        audio_master.info(audio_file_empty)
      }.to raise_error(Exceptions::FileEmptyError)

    end

    it 'gives correct error for corrupt file' do
      expect {
        audio_master.info(audio_file_corrupt)
      }.to raise_error(Exceptions::FileCorruptError)
    end

    it 'gets the correct channel count for mono audio file' do
      info = audio_master.info(audio_file_mono)
      expect(info[:channels]).to eql(1)
    end

    it 'gets the correct channel count for stereo audio file' do
      info = audio_master.info(audio_file_stereo)
      expect(info[:channels]).to eql(2)
    end

    it 'gets the correct channel count for 3 channel audio file' do
      info = audio_master.info(audio_file_3_channels)
      expect(info[:channels]).to eql(3)
    end


    it 'returns all required information' do
      info = audio_master.info(audio_file_stereo)
      expect(info).to include(:media_type)
      expect(info).to include(:sample_rate_hertz)
      expect(info).to include(:bit_rate_bps)
      expect(info).to include(:data_length_bytes)
      expect(info).to include(:channels)
      expect(info).to include(:duration_seconds)
      expect(info.size).to eq(6)
    end
    it 'gives correct error for empty file' do
      expect {
        audio_master.info(audio_file_empty)
      }.to raise_error(Exceptions::FileEmptyError)

    end

    it 'gives correct error for corrupt file' do
      expect {
        audio_master.info(audio_file_corrupt)
      }.to raise_error(Exceptions::FileCorruptError)
    end


    context 'when modifying audio file' do
      it 'causes exception for invalid path' do
        expect {
          audio_master.modify(audio_file_does_not_exist_1, audio_file_does_not_exist_2, {})
        }.to raise_error(Exceptions::FileNotFoundError)
      end

      it 'causes exception for same path for source and target' do
        expect {
          audio_master.modify(audio_file_stereo, audio_file_stereo, {})
        }.to raise_error(ArgumentError, /Source and Target are the same file/)
      end

      context 'restrictions are enforced' do
        it 'mp3splt must have a mp3 file as the source' do
          temp_audio_file = temp_audio_file_1+'.mp3'
          expect {
            audio_master.audio_mp3splt.modify(audio_file_stereo, temp_audio_file, {})
          }.to raise_error(ArgumentError, /Source is not a mp3 file/)
        end

        it 'mp3splt must have a mp3 file as the destination' do
          temp_audio_file_a = temp_audio_file_1+'.mp3'
          result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
          info_1 = audio_master.info(temp_audio_file_a)
          expect(info_1[:media_type]).to eq('audio/mp3')
          expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_1[:channels]).to eq(audio_file_stereo_channels)
          expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

          temp_audio_file_b = temp_audio_file_2+'.wav'

          expect {
            audio_master.audio_mp3splt.modify(temp_audio_file_a, temp_audio_file_b, {})
          }.to raise_error(ArgumentError, /not a mp3 file/)
        end

        it 'wavpack must have a wavpack file as the source' do
          temp_audio_file = temp_audio_file_1+'.mp3'
          expect {
            audio_master.audio_wavpack.modify(audio_file_stereo, temp_audio_file, {})
          }.to raise_error(ArgumentError, /Source is not a wavpack file/)
        end

        it 'wavpack must have a wav file as the destination' do
          temp_audio_file_a = temp_audio_file_1+'.wv'
          result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
          info_1 = audio_master.info(temp_audio_file_a)
          expect(info_1[:media_type]).to eq('audio/wavpack')
          expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_1[:channels]).to eq(audio_file_stereo_channels)
          expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

          temp_audio_file_b = temp_audio_file_2+'.wv'

          expect {
            audio_master.audio_wavpack.modify(temp_audio_file_a, temp_audio_file_b, {})
          }.to raise_error(ArgumentError, /not a wav pack file/)
        end
      end

      context 'processing entire file' do
        it 'correctly converts from .ogg to .wav' do
          temp_audio_file = temp_audio_file_1+'.wav'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/wav')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .oga' do
          temp_audio_file = temp_audio_file_1+'.oga'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/ogg')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .mp3' do
          temp_audio_file = temp_audio_file_1+'.mp3'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/mp3')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .asf' do
          temp_audio_file = temp_audio_file_1+'.asf'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/asf')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .mp4' do
          temp_audio_file = temp_audio_file_1+'.mp4'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/mp4')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .aac' do
          temp_audio_file = temp_audio_file_1+'.aac'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/aac')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .webm' do
          temp_audio_file = temp_audio_file_1+'.webm'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/webm')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .webma' do
          temp_audio_file = temp_audio_file_1+'.webma'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/webm')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .wv' do
          temp_audio_file = temp_audio_file_1+'.wv'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/wavpack')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .wav, then from .wav to .mp3' do
          temp_audio_file_a = temp_audio_file_1+'.wav'
          result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
          info_1 = audio_master.info(temp_audio_file_a)
          expect(info_1[:media_type]).to eq('audio/wav')
          expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_1[:channels]).to eq(audio_file_stereo_channels)
          expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

          temp_audio_file_b = temp_audio_file_2+'.mp3'
          result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {})
          info_2 = audio_master.info(temp_audio_file_b)
          expect(info_2[:media_type]).to eq('audio/mp3')
          expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_2[:channels]).to eq(audio_file_stereo_channels)
          expect(info_2[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .wav, then from .wav to .ogg' do
          temp_audio_file_a = temp_audio_file_1+'.wav'
          result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
          info_1 = audio_master.info(temp_audio_file_a)
          expect(info_1[:media_type]).to eq('audio/wav')
          expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_1[:channels]).to eq(audio_file_stereo_channels)
          expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

          temp_audio_file_b = temp_audio_file_2+'.ogg'
          result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {})
          info_2 = audio_master.info(temp_audio_file_b)
          expect(info_2[:media_type]).to eq('audio/ogg')
          expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_2[:channels]).to eq(audio_file_stereo_channels)
          expect(info_2[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end

        it 'correctly converts from .ogg to .mp3, then from .mp3 to .wav' do
          temp_audio_file_a = temp_audio_file_1+'.mp3'
          result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
          info_1 = audio_master.info(temp_audio_file_a)
          expect(info_1[:media_type]).to eq('audio/mp3')
          expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_1[:channels]).to eq(audio_file_stereo_channels)
          expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

          temp_audio_file_b = temp_audio_file_2+'.wav'
          result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {})
          info_2 = audio_master.info(temp_audio_file_b)
          expect(info_2[:media_type]).to eq('audio/wav')
          expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_2[:channels]).to eq(audio_file_stereo_channels)
          expect(info_2[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)
        end
      end

      context 'segmenting audio file' do

        it 'gets the correct segment of the file when only start_offset is specified' do
          temp_audio_file = temp_audio_file_1+'.wav'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {start_offset: 10})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/wav')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds - 10)
        end

        it 'gets the correct segment of the file when only end_offset is specified' do
          temp_audio_file = temp_audio_file_1+'.wav'
          result = audio_master.modify(audio_file_stereo, temp_audio_file, {end_offset: 20})
          info = audio_master.info(temp_audio_file)
          expect(info[:media_type]).to eq('audio/wav')
          expect(info[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info[:channels]).to eq(audio_file_stereo_channels)
          expect(info[:duration_seconds]).to be_within(duration_range).of(20)
        end

        it 'correctly converts from .ogg to .wv, then to from .wv to .wav' do
          temp_audio_file_a = temp_audio_file_1+'.wv'
          result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {start_offset: 10, end_offset: 20})
          info_1 = audio_master.info(temp_audio_file_a)
          expect(info_1[:media_type]).to eq('audio/wavpack')
          expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_1[:channels]).to eq(audio_file_stereo_channels)
          expect(info_1[:duration_seconds]).to be_within(duration_range).of(10)

          temp_audio_file_b = temp_audio_file_2+'.wav'
          result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {})
          info_2 = audio_master.info(temp_audio_file_b)
          expect(info_2[:media_type]).to eq('audio/wav')
          expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_2[:channels]).to eq(audio_file_stereo_channels)
          expect(info_2[:duration_seconds]).to be_within(duration_range).of(10)
        end

        it 'correctly converts from .ogg to .webm, then to from .webm to .ogg' do
          temp_audio_file_a = temp_audio_file_1+'.webm'
          result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {start_offset: 10, end_offset: 20})
          info_1 = audio_master.info(temp_audio_file_a)
          expect(info_1[:media_type]).to eq('audio/webm')
          expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_1[:channels]).to eq(audio_file_stereo_channels)
          expect(info_1[:duration_seconds]).to be_within(duration_range).of(10)

          temp_audio_file_b = temp_audio_file_2+'.ogg'
          result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {})
          info_2 = audio_master.info(temp_audio_file_b)
          expect(info_2[:media_type]).to eq('audio/ogg')
          expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
          expect(info_2[:channels]).to eq(audio_file_stereo_channels)
          expect(info_2[:duration_seconds]).to be_within(duration_range).of(10)
        end

        context 'special case for wavpack files' do
          it 'gets the correct segment of the file when only start_offset is specified' do
            temp_audio_file_a = temp_audio_file_1+'.wv'
            result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
            info_1 = audio_master.info(temp_audio_file_a)
            expect(info_1[:media_type]).to eq('audio/wavpack')
            expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_1[:channels]).to eq(audio_file_stereo_channels)
            expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

            temp_audio_file_b = temp_audio_file_2+'.wav'
            result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {start_offset: 10})
            info_2 = audio_master.info(temp_audio_file_b)
            expect(info_2[:media_type]).to eq('audio/wav')
            expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_2[:channels]).to eq(audio_file_stereo_channels)
            expect(info_2[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds - 10)
          end

          it 'gets the correct segment of the file when only end_offset is specified' do
            temp_audio_file_a = temp_audio_file_1+'.wv'
            result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
            info_1 = audio_master.info(temp_audio_file_a)
            expect(info_1[:media_type]).to eq('audio/wavpack')
            expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_1[:channels]).to eq(audio_file_stereo_channels)
            expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

            temp_audio_file_b = temp_audio_file_2+'.wav'
            result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {end_offset: 20})
            info_2 = audio_master.info(temp_audio_file_b)
            expect(info_2[:media_type]).to eq('audio/wav')
            expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_2[:channels]).to eq(audio_file_stereo_channels)
            expect(info_2[:duration_seconds]).to be_within(duration_range).of(20)
          end

          it 'gets the correct segment of the file when only offsets are specified' do
            temp_audio_file_a = temp_audio_file_1+'.wv'
            result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
            info_1 = audio_master.info(temp_audio_file_a)
            expect(info_1[:media_type]).to eq('audio/wavpack')
            expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_1[:channels]).to eq(audio_file_stereo_channels)
            expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

            temp_audio_file_b = temp_audio_file_2+'.wav'
            result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {start_offset: 10, end_offset: 20})
            info_2 = audio_master.info(temp_audio_file_b)
            expect(info_2[:media_type]).to eq('audio/wav')
            expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_2[:channels]).to eq(audio_file_stereo_channels)
            expect(info_2[:duration_seconds]).to be_within(duration_range).of(10)
          end
        end

        context 'special case for mp3 files' do
          it 'gets the correct segment of the file when only start_offset is specified' do
            temp_audio_file_a = temp_audio_file_1+'.mp3'
            result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
            info_1 = audio_master.info(temp_audio_file_a)
            expect(info_1[:media_type]).to eq('audio/mp3')
            expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_1[:channels]).to eq(audio_file_stereo_channels)
            expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

            temp_audio_file_b = temp_audio_file_2+'.mp3'
            result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {start_offset: 10})
            info_2 = audio_master.info(temp_audio_file_b)
            expect(info_2[:media_type]).to eq('audio/mp3')
            expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_2[:channels]).to eq(audio_file_stereo_channels)
            expect(info_2[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds - 10)
          end

          it 'gets the correct segment of the file when only end_offset is specified' do
            temp_audio_file_a = temp_audio_file_1+'.mp3'
            result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
            info_1 = audio_master.info(temp_audio_file_a)
            expect(info_1[:media_type]).to eq('audio/mp3')
            expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_1[:channels]).to eq(audio_file_stereo_channels)
            expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

            temp_audio_file_b = temp_audio_file_2+'.mp3'
            result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {end_offset: 20})
            info_2 = audio_master.info(temp_audio_file_b)
            expect(info_2[:media_type]).to eq('audio/mp3')
            expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_2[:channels]).to eq(audio_file_stereo_channels)
            expect(info_2[:duration_seconds]).to be_within(duration_range).of(20)
          end

          it 'gets the correct segment of the file when only offsets are specified' do
            temp_audio_file_a = temp_audio_file_1+'.mp3'
            result_1 = audio_master.modify(audio_file_stereo, temp_audio_file_a, {})
            info_1 = audio_master.info(temp_audio_file_a)
            expect(info_1[:media_type]).to eq('audio/mp3')
            expect(info_1[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_1[:channels]).to eq(audio_file_stereo_channels)
            expect(info_1[:duration_seconds]).to be_within(duration_range).of(audio_file_stereo_duration_seconds)

            temp_audio_file_b = temp_audio_file_2+'.mp3'
            result_2 = audio_master.modify(temp_audio_file_a, temp_audio_file_b, {start_offset: 10, end_offset: 20})
            info_2 = audio_master.info(temp_audio_file_b)
            expect(info_2[:media_type]).to eq('audio/mp3')
            expect(info_2[:sample_rate_hertz]).to be_within(0.0).of(audio_file_stereo_sample_rate)
            expect(info_2[:channels]).to eq(audio_file_stereo_channels)
            expect(info_2[:duration_seconds]).to be_within(duration_range).of(10)
          end
        end

      end
    end
  end
end