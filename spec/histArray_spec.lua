local HistArray = require "histArray"

-- The HistArray module provides an array that automatically purges
-- old values. It lets you write code like:
--
-- y[n] = c1*x[n] + c2*x[n-1] + c3*x[n-2]
--                - c4*y[n-1] - c5*y[n-2]
--
-- If x and y are HistArrays created with history size 2, all samples from
-- x[n-3] and y[n-3] and below will be purged (accessing them is an error)
-- so that the no longer needed values do not waste any memory.
--
-- HistArray stands for history array.
--
-- FAQ:    How does a HistArray know when to purge old values?
-- Answer: For all n, when y[n] is assigned to, y[n - (y.histSize+1)]
--         and below are purged.  This allows most recurrence relations
--         (like the above) to be defined in a natural manner.

describe("a history array", function()
    it("has a history size", function()
        local y = HistArray.new(2)
        assert.are.equal(2, y.histSize)
    end)

    it("holds as many values as its history size, plus one", function()
        local y = HistArray.new(2)
        y[1] = 0.1
        y[2] = 0.2
        y[3] = 0.3
        y[4] = 0.4
        assert.are.equal(0.4, y[4])  -- current value
        assert.are.equal(0.3, y[3])  -- current minus 1
        assert.are.equal(0.2, y[2])  -- current minus 2
        assert.has_error(function() local _ = y[1] end)  -- too old!
    end)

    it("starts with histSize+1 zeroes", function()
        local y = HistArray.new(5)
        assert.are.equal(0, y[0], y[-1], y[-2], y[-3], y[-4])
        assert.has_error(function() local _ = y[-5] end)
    end)

    it("returns its values as a table with the :all method", function()
        local y = HistArray.new(3)
        y[1] = 50
        y[2] = 100
        y[3] = 31337
        assert.are.same({[3]=31337, [2]=100, [1]=50, [0]=0}, y:all())
    end)

    it("fills in zeroes if an index is skipped during assignment", function()
        local y = HistArray.new(3)
        y[1] = 1
        y[2] = 2
        -- Skip a few
        y[5] = 5
        assert.are.same({[5]=5, [4]=0, [3]=0, [2]=2}, y:all())
    end)

    it("won't let you assign out of order", function()
        local y = HistArray.new(2)
        y[1] = 1
        y[3] = 3  -- This might be weird, but it's legit (see above).
        assert.has_error(function()
            y[2] = 2  -- This isn't legit. Can't assign 2 after 3.
        end)
    end)

    it("won't let you reassign an index", function()
        local y = HistArray.new(2)
        y[1] = 1
        assert.has_error(function()
            y[1] = 0  -- Can't do, y[1] was already set.
        end)
        -- The reason for this behavior is to better match a recurrence
        -- relation. Use a temp variable to calculate the value, *then*
        -- put it into the HistArray.
    end)

    it("won't let you assign a nonpositive index, even to start", function()
        assert.has_error(function()
            local y = HistArray.new(2)
            y[0] = 1
        end, "Attempt to assign nonpositive index")
        assert.has_error(function()
            local y = HistArray.new(2)
            y[-50000] = 1
        end, "Attempt to assign nonpositive index")
    end)

    it("can handle really freakin' huge indices", function()
        local y = HistArray.new(2)
        y[15000] = 10
        assert.are.same({[15000] = 10, [14999] = 0, [14998] = 0}, y:all())

        local big = 12345678901234567890
        y[big] = -100
        big = big + 1
        y[big] = 1
        assert.are.same({[big] = 1, [big-1] = -100, [big-2] = 0}, y:all())
    end)
end)
