require 'spec_helper'

describe Api::FilterQuery do

  def create_filter(params)
    Api::FilterQuery.new(
        params,
        AudioRecording,
        AudioRecording.valid_fields,
        AudioRecording.text_fields
    )
  end

  # none_relation, direction asc
  # unrecognised filter
  # and, or, not, other (error)
  # range errors (missing from/to, interval), interval outside range?
  context 'errors' do

    it 'occur when a filter is not recognised' do
      expect {
        create_filter(
            {
                filter: {
                    or: [
                        {
                            recorded_date: {
                                not_a_real_filter: 'Hello'
                            }
                        }
                    ]
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Unrecognised filter not_a_real_filter/)
    end

    it 'occur when a combiner has only 1 entry' do
      expect {
        create_filter(
            {
                filter: {
                    not_a_valid_combiner: [
                        {
                            recorded_date: {
                                contains: 'Hello'
                            }
                        }
                    ]
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Conditions array must have at least 2 entries, got 1/)
    end

    it 'occur when a combiner has no entries' do
      expect {
        create_filter(
            {
                filter: {
                    not_a_valid_combiner: [
                    ]
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Conditions array must have at least 2 entries, got 0/)
    end

    it 'occur when a combiner is not recognised' do
      expect {
        create_filter(
            {
                filter: {
                    not_a_valid_combiner: [
                        {
                            recorded_date: {
                                contains: 'Hello'
                            }
                        },
                        {
                            site_id: {
                                contains: 'Hello'
                            }
                        }
                    ]
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Unrecognised filter combiner not_a_valid_combiner/)
    end

#
    it "occur when a range is missing 'from'" do
      expect {
        create_filter(
            {
                filter: {
                    site_id: {
                        range: {
                            to: 200
                        }
                    }
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Range filter missing 'from'/)
    end

    it "occur when a range is missing 'to'" do
      expect {
        create_filter(
            {
                filter: {
                    site_id: {
                        range: {
                            from: 200
                        }
                    }
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Range filter missing 'to'/)
    end

    it 'occur when a range has from/to and interval' do
      expect {
        create_filter(
            {
                filter: {
                    site_id: {
                        range: {
                            from: 200,
                            to:200,
                            interval: '[1,2]'
                        }
                    }
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Range filter must use either 'from' and 'to' or 'interval', not both/)
    end

    it 'occur when a range has no recognised properties' do
      expect {
        create_filter(
            {
                filter: {
                    site_id: {
                        range: {
                            ignored_in_a_range: '[34,34]'
                        }
                    }
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Range filter was not valid/)
    end

    it 'occur when a property has no filters' do
      expect {
        create_filter(
            {
                filter: {
                    site_id: {
                    }
                }
            }
        ).query_full
      }.to raise_error(ArgumentError, /Conditions hash must have at least 1 entry, got 0/)
    end

  end
  context 'complex query' do
    let(:complex_sample) {
      #Sample POST url and json body

      #POST /audio_recordings/filter?filter_notes=hello&filter_partial_match=testing_testing
      #POST /audio_recordings/filter?filter_notes=hello&filter_channels=28&filter_partial_match=testing_testing

      {
          filter: {
              site_id: {
                  less_than: 123456,
                  greater_than: 012345,
                  in: [
                      1,
                      2,
                      3
                  ],
                  range: {
                      from: 100,
                      to: 200
                  }
              },
              notes: {
                  greater_than_or_equal: 012345,
                  contains: 'contain text',
                  starts_with: 'starts with text',
                  ends_with: 'ends with text',
                  range: {
                      interval: '[123, 128]'
                  }
              },
              or: [
                  {
                      recorded_date: {
                          contains: 'Hello'
                      }
                  },
                  {
                      file_hash: {
                          ends_with: 'world'
                      }
                  },
                  {
                      duration_seconds: {
                          eq: 60,
                          lteq: 70
                      }
                  },
                  {
                      duration_seconds: {
                          equal: 50,
                          gteq: 80
                      }
                  }
              ],
              and: [
                  {
                      duration_seconds: {
                          not_eq: 40
                      }
                  },
                  {
                      channels: {
                          eq: 2,
                          less_than_or_equal: 012345
                      }
                  }
              ],
              not: [
                  {
                      duration_seconds: {
                          not_eq: 140
                      }
                  },
                  {
                      channels: {
                          eq: 1,
                          less_than_or_equal: 54321
                      }
                  }
              ]
          },
          sort: {
              orderBy: 'duration_seconds',
              direction: 'desc'
          },
          paging: {
              offset: 0,
              limit: 10,
              next: 'http://host.domain/resource?offset=1&limit=10',
              previous: 'http://host.domain/resource?offset=1&limit=10'
          },
          filter_notes: 'hello',
          filter_channels: 28,
          filter_partial_match: 'testing_testing'
      }
    }

    let(:complex_result) {
"SELECT  \"audio_recordings\".* \
FROM \"audio_recordings\" \
WHERE \
\"audio_recordings\".\"site_id\" IN (1, 2, 3) \
AND (\"audio_recordings\".\"deleted_at\" IS NULL) \
AND (\"audio_recordings\".\"site_id\" < 123456) \
AND (\"audio_recordings\".\"site_id\" > 5349) \
AND (\"audio_recordings\".\"site_id\" >= 100 \
AND \"audio_recordings\".\"site_id\" < 200)  \
AND (\"audio_recordings\".\"notes\" >= 5349)  \
AND (\"audio_recordings\".\"notes\" ILIKE '%contain text%')  \
AND (\"audio_recordings\".\"notes\" ILIKE 'starts with text%')  \
AND (\"audio_recordings\".\"notes\" ILIKE '%ends with text')  \
AND (\"audio_recordings\".\"notes\" BETWEEN '123' AND ' 128')  \
AND ( \
( \
( \
( \
( \
(\"audio_recordings\".\"recorded_date\" ILIKE '%Hello%' \
OR \"audio_recordings\".\"file_hash\" ILIKE '%world') \
OR \"audio_recordings\".\"duration_seconds\" = 60) \
OR \"audio_recordings\".\"duration_seconds\" <= 70) \
OR \"audio_recordings\".\"duration_seconds\" = 50) \
OR \"audio_recordings\".\"duration_seconds\" >= 80)) \
AND (\"audio_recordings\".\"duration_seconds\" != 40 \
AND \"audio_recordings\".\"channels\" = 2 \
AND \"audio_recordings\".\"channels\" <= 5349) \
AND (NOT (\"audio_recordings\".\"duration_seconds\" != 140)) \
AND (NOT (\"audio_recordings\".\"channels\" = 1)) \
AND (NOT (\"audio_recordings\".\"channels\" <= 54321)) \
AND ( \
( \
(\"audio_recordings\".\"notes\" ILIKE '%testing\\_testing%' \
OR \"audio_recordings\".\"status\" ILIKE '%testing\\_testing%') \
OR \"audio_recordings\".\"original_file_name\" ILIKE '%testing\\_testing%')) \
AND (\"audio_recordings\".\"notes\" = 'hello' \
AND \"audio_recordings\".\"channels\" = 28) \
ORDER BY \"audio_recordings\".\"duration_seconds\" \
DESC LIMIT 10 OFFSET 0"
    }

    it 'generates expected SQL' do
      filter_query = create_filter(complex_sample)
      expect(filter_query.query_full.to_sql.gsub(/\s+/, '')).to eq(complex_result.gsub(/\s+/, ''))
    end
  end
end
